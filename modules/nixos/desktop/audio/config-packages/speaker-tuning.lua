-- Loudness compensation for a physical sink.
--
-- The LSP loudness plugin rebuilds its response when its `volume` control is
-- changed.  Updating that control while its audio is audible causes the short
-- burp that this policy replaces.  The filter-chain below has two independent
-- floor/ceil pairs.  One pair renders while the other pair is muted and can be
-- prepared for the next volume range.  PipeWire's builtin ramp nodes perform
-- the hand-off entirely in the real-time graph.

local LOG_PREFIX = CFG.log_prefix
local PHONS_REFERENCE = 83.0
local MIN_VOLUME_DB = -83.0
local MAX_VOLUME_DB = 7.0
local EPSILON = 0.000001

local reference_volume_db = 20.0 * math.log(CFG.reference_volume_linear) / math.log(10.0)
local calibration_offset_db = CFG.reference_spl - PHONS_REFERENCE - reference_volume_db
local calibration_gain_linear = 10.0 ^ (-calibration_offset_db / 20.0)

local PAIRS = {
  {
    low = "pair0_low",
    high = "pair0_high",
  },
  {
    low = "pair1_low",
    high = "pair1_high",
  },
}

local BRANCHES = {
  "pair0_low",
  "pair0_high",
  "pair1_low",
  "pair1_high",
}

local runtime = {
  target_metadata = nil,
  graph_module = nil,
  graph_node = nil,
  metadata_om = nil,
  target_om = nil,
  graph_om = nil,
  enforcing_physical_volume = false,
  transition_timer = nil,
  generation = 0,
  active_pair = nil,
  pair_curves = { nil, nil },
  gains = {
    pair0_low = 0.0,
    pair0_high = 0.0,
    pair1_low = 0.0,
    pair1_high = 0.0,
  },
  pending_target = nil,
  last_linear = nil,
  last_mute = nil,
}

local function clamp(value, minimum, maximum)
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

local function parse_props_param(pod)
  local parsed = pod:parse()
  if type(parsed) ~= "table" then return nil end
  return parsed.properties
end

local function read_linear_from_props(props)
  if type(props) ~= "table" then return nil end

  local channel_volumes = props.channelVolumes
  if type(channel_volumes) == "table" and #channel_volumes > 0 then
    local sum = 0.0
    local count = 0
    for _, value in ipairs(channel_volumes) do
      if type(value) == "number" then
        sum = sum + value
        count = count + 1
      elseif type(value) == "table" and type(value[1]) == "number" then
        sum = sum + value[1]
        count = count + 1
      elseif type(value) == "table" and type(value.value) == "number" then
        sum = sum + value.value
        count = count + 1
      end
    end
    if count > 0 then return sum / count end
  end

  if type(props.volume) == "number" then return props.volume end
  return nil
end

local function append_control(controls, name, value)
  controls[#controls + 1] = name
  controls[#controls + 1] = Pod.Float(value)
end

local function set_graph_controls(controls)
  if not runtime.graph_node or #controls == 0 then return end

  runtime.graph_node:set_param("Props", Pod.Object {
    "Spa:Pod:Object:Param:Props", "Props",
    params = Pod.Struct(controls),
  })
end

local function append_pair_curve_controls(controls, pair_index, target)
  local pair = PAIRS[pair_index]
  append_control(controls, pair.low .. "_eq:volume", target.lower_db)
  append_control(controls, pair.high .. "_eq:volume", target.upper_db)
end

local function append_ramp_controls(controls, branch, start, stop)
  append_control(controls, branch .. "_ramp:Start", start)
  append_control(controls, branch .. "_ramp:Stop", stop)
  append_control(controls, branch .. "_ramp:Duration (s)", CFG.crossfade_duration_ms / 1000.0)
end

local function target_from_volume(linear, muted)
  if muted or linear == nil or linear <= EPSILON then
    return { muted = true }
  end

  local user_db = 20.0 * math.log(clamp(linear, EPSILON, 1.0)) / math.log(10.0)
  local loudness_db = clamp(user_db + calibration_offset_db, MIN_VOLUME_DB, MAX_VOLUME_DB)
  local lower_db = math.floor(loudness_db)
  local fraction = loudness_db - lower_db
  local upper_db = lower_db + 1.0

  if upper_db > MAX_VOLUME_DB then
    upper_db = MAX_VOLUME_DB
    fraction = 0.0
  end

  return {
    muted = false,
    lower_db = lower_db,
    upper_db = upper_db,
    low_gain = 1.0 - fraction,
    high_gain = fraction,
  }
end

local function same_curve(left, right)
  return left ~= nil
    and right ~= nil
    and left.lower_db == right.lower_db
    and left.upper_db == right.upper_db
end

local function gains_for_pair(pair_index, target)
  local result = {
    pair0_low = 0.0,
    pair0_high = 0.0,
    pair1_low = 0.0,
    pair1_high = 0.0,
  }

  if target ~= nil and not target.muted then
    local pair = PAIRS[pair_index]
    result[pair.low] = target.low_gain
    result[pair.high] = target.high_gain
  end

  return result
end

local function apply_ramps(next_gains)
  local controls = {}
  for _, branch in ipairs(BRANCHES) do
    append_ramp_controls(controls, branch, runtime.gains[branch], next_gains[branch])
  end
  set_graph_controls(controls)
  runtime.gains = next_gains
end

local function schedule_transition_complete(active_pair)
  local generation = runtime.generation
  runtime.transition_timer = Core.timeout_add(CFG.crossfade_duration_ms, function()
    if generation ~= runtime.generation then return false end

    runtime.transition_timer = nil
    runtime.active_pair = active_pair

    if runtime.pending_target ~= nil then
      local target = runtime.pending_target
      runtime.pending_target = nil
      -- The preceding ramps have reached their programmed stops, so the pair
      -- not selected above is guaranteed silent before it is retuned.
      local function start_pending()
        if target.muted then
          apply_ramps(gains_for_pair(1, nil))
          schedule_transition_complete(nil)
          return
        end

        if runtime.active_pair == nil then
          local initial_pair = 1
          local controls = {}
          append_pair_curve_controls(controls, initial_pair, target)
          set_graph_controls(controls)
          runtime.pair_curves[initial_pair] = target
          apply_ramps(gains_for_pair(initial_pair, target))
          schedule_transition_complete(initial_pair)
          return
        end

        local current_pair = runtime.active_pair
        if same_curve(runtime.pair_curves[current_pair], target) then
          apply_ramps(gains_for_pair(current_pair, target))
          schedule_transition_complete(current_pair)
          return
        end

        local next_pair = current_pair == 1 and 2 or 1
        local controls = {}
        append_pair_curve_controls(controls, next_pair, target)
        set_graph_controls(controls)
        runtime.pair_curves[next_pair] = target
        apply_ramps(gains_for_pair(next_pair, target))
        schedule_transition_complete(next_pair)
      end

      start_pending()
    end

    return false
  end)
end

local function request_target(target)
  runtime.pending_target = target
  if runtime.transition_timer ~= nil or runtime.graph_node == nil then return end

  local pending = runtime.pending_target
  runtime.pending_target = nil

  if pending.muted then
    apply_ramps(gains_for_pair(1, nil))
    schedule_transition_complete(nil)
    return
  end

  if runtime.active_pair == nil then
    local initial_pair = 1
    local controls = {}
    append_pair_curve_controls(controls, initial_pair, pending)
    set_graph_controls(controls)
    runtime.pair_curves[initial_pair] = pending
    apply_ramps(gains_for_pair(initial_pair, pending))
    schedule_transition_complete(initial_pair)
    return
  end

  local current_pair = runtime.active_pair
  if same_curve(runtime.pair_curves[current_pair], pending) then
    apply_ramps(gains_for_pair(current_pair, pending))
    schedule_transition_complete(current_pair)
    return
  end

  local next_pair = current_pair == 1 and 2 or 1
  local controls = {}
  append_pair_curve_controls(controls, next_pair, pending)
  set_graph_controls(controls)
  runtime.pair_curves[next_pair] = pending
  apply_ramps(gains_for_pair(next_pair, pending))
  schedule_transition_complete(next_pair)
end

local function force_physical_sink_volume(node)
  if runtime.enforcing_physical_volume then return end

  local need_update = true
  for pod in node:iterate_params("Props") do
    local props = parse_props_param(pod)
    if type(props) == "table" then
      local volume = props.volume
      local mute = props.mute
      if type(volume) == "number" and math.abs(volume - 1.0) < 0.0001 and mute == false then
        need_update = false
      end
    end
    break
  end

  if not need_update then return end

  runtime.enforcing_physical_volume = true
  node:set_param("Props", Pod.Object {
    "Spa:Pod:Object:Param:Props", "Props",
    volume = 1.0,
    mute = false,
  })
  runtime.enforcing_physical_volume = false
end

local function unload_modules()
  runtime.generation = runtime.generation + 1
  runtime.graph_module = nil
  runtime.graph_node = nil
  runtime.transition_timer = nil
  runtime.active_pair = nil
  runtime.pair_curves = { nil, nil }
  runtime.gains = {
    pair0_low = 0.0,
    pair0_high = 0.0,
    pair1_low = 0.0,
    pair1_high = 0.0,
  }
  runtime.pending_target = nil
  runtime.last_linear = nil
  runtime.last_mute = nil
end

local function load_modules(node)
  if runtime.graph_module then return end

  local raw_desc = node.properties["node.description"] or "Unknown Sink"
  local tuned_desc = CFG.override_desc or (raw_desc .. " w/ Loudness Compensation")
  Log.info(LOG_PREFIX .. "target detected; loading loudness sink as: " .. tuned_desc)

  local args = [[
    {
      "node.description": "]] .. tuned_desc .. [[",
      "media.name": "]] .. tuned_desc .. [[",
      "filter.graph": {
        "nodes": [
          { "type": "builtin", "name": "copy_l", "label": "copy" },
          { "type": "builtin", "name": "copy_r", "label": "copy" },
          {
            "type": "lv2", "name": "pair0_low_eq",
            "plugin": "http://lsp-plug.in/plugins/lv2/loud_comp_stereo",
            "label": "loud_comp_stereo",
            "control": {
              "volume": -83.0, "std": ]] .. CFG.std .. [[, "mode": ]] .. CFG.mode .. [[,
              "fft": ]] .. CFG.fft .. [[, "approx": ]] .. CFG.approx .. [[,
              "hclip": ]] .. CFG.hclip .. [[, "hcrange": ]] .. CFG.hcrange .. [[
            }
          },
          {
            "type": "lv2", "name": "pair0_high_eq",
            "plugin": "http://lsp-plug.in/plugins/lv2/loud_comp_stereo",
            "label": "loud_comp_stereo",
            "control": {
              "volume": -83.0, "std": ]] .. CFG.std .. [[, "mode": ]] .. CFG.mode .. [[,
              "fft": ]] .. CFG.fft .. [[, "approx": ]] .. CFG.approx .. [[,
              "hclip": ]] .. CFG.hclip .. [[, "hcrange": ]] .. CFG.hcrange .. [[
            }
          },
          {
            "type": "lv2", "name": "pair1_low_eq",
            "plugin": "http://lsp-plug.in/plugins/lv2/loud_comp_stereo",
            "label": "loud_comp_stereo",
            "control": {
              "volume": -83.0, "std": ]] .. CFG.std .. [[, "mode": ]] .. CFG.mode .. [[,
              "fft": ]] .. CFG.fft .. [[, "approx": ]] .. CFG.approx .. [[,
              "hclip": ]] .. CFG.hclip .. [[, "hcrange": ]] .. CFG.hcrange .. [[
            }
          },
          {
            "type": "lv2", "name": "pair1_high_eq",
            "plugin": "http://lsp-plug.in/plugins/lv2/loud_comp_stereo",
            "label": "loud_comp_stereo",
            "control": {
              "volume": -83.0, "std": ]] .. CFG.std .. [[, "mode": ]] .. CFG.mode .. [[,
              "fft": ]] .. CFG.fft .. [[, "approx": ]] .. CFG.approx .. [[,
              "hclip": ]] .. CFG.hclip .. [[, "hcrange": ]] .. CFG.hcrange .. [[
            }
          },
          { "type": "builtin", "name": "pair0_low_ramp", "label": "ramp" },
          { "type": "builtin", "name": "pair0_high_ramp", "label": "ramp" },
          { "type": "builtin", "name": "pair1_low_ramp", "label": "ramp" },
          { "type": "builtin", "name": "pair1_high_ramp", "label": "ramp" },
          { "type": "builtin", "name": "pair0_low_l", "label": "mult" },
          { "type": "builtin", "name": "pair0_low_r", "label": "mult" },
          { "type": "builtin", "name": "pair0_high_l", "label": "mult" },
          { "type": "builtin", "name": "pair0_high_r", "label": "mult" },
          { "type": "builtin", "name": "pair1_low_l", "label": "mult" },
          { "type": "builtin", "name": "pair1_low_r", "label": "mult" },
          { "type": "builtin", "name": "pair1_high_l", "label": "mult" },
          { "type": "builtin", "name": "pair1_high_r", "label": "mult" },
          {
            "type": "builtin", "name": "mix_l", "label": "mixer",
            "control": { "Gain 1": 1.0, "Gain 2": 1.0, "Gain 3": 1.0, "Gain 4": 1.0 }
          },
          {
            "type": "builtin", "name": "mix_r", "label": "mixer",
            "control": { "Gain 1": 1.0, "Gain 2": 1.0, "Gain 3": 1.0, "Gain 4": 1.0 }
          },
          {
            "type": "builtin", "name": "calibration_gain_l", "label": "linear",
            "control": { "Mult": ]] .. tostring(calibration_gain_linear) .. [[, "Add": 0.0 }
          },
          {
            "type": "builtin", "name": "calibration_gain_r", "label": "linear",
            "control": { "Mult": ]] .. tostring(calibration_gain_linear) .. [[, "Add": 0.0 }
          },
          {
            "type": "builtin", "name": "volume_probe", "label": "linear",
            "control": { "Mult": 1.0, "Add": 0.0 }
          }
        ],
        "links": [
          { "output": "copy_l:Out", "input": "pair0_low_eq:in_l" },
          { "output": "copy_r:Out", "input": "pair0_low_eq:in_r" },
          { "output": "copy_l:Out", "input": "pair0_high_eq:in_l" },
          { "output": "copy_r:Out", "input": "pair0_high_eq:in_r" },
          { "output": "copy_l:Out", "input": "pair1_low_eq:in_l" },
          { "output": "copy_r:Out", "input": "pair1_low_eq:in_r" },
          { "output": "copy_l:Out", "input": "pair1_high_eq:in_l" },
          { "output": "copy_r:Out", "input": "pair1_high_eq:in_r" },

          { "output": "pair0_low_eq:out_l", "input": "pair0_low_l:In 1" },
          { "output": "pair0_low_eq:out_r", "input": "pair0_low_r:In 1" },
          { "output": "pair0_high_eq:out_l", "input": "pair0_high_l:In 1" },
          { "output": "pair0_high_eq:out_r", "input": "pair0_high_r:In 1" },
          { "output": "pair1_low_eq:out_l", "input": "pair1_low_l:In 1" },
          { "output": "pair1_low_eq:out_r", "input": "pair1_low_r:In 1" },
          { "output": "pair1_high_eq:out_l", "input": "pair1_high_l:In 1" },
          { "output": "pair1_high_eq:out_r", "input": "pair1_high_r:In 1" },

          { "output": "pair0_low_ramp:Out", "input": "pair0_low_l:In 2" },
          { "output": "pair0_low_ramp:Out", "input": "pair0_low_r:In 2" },
          { "output": "pair0_high_ramp:Out", "input": "pair0_high_l:In 2" },
          { "output": "pair0_high_ramp:Out", "input": "pair0_high_r:In 2" },
          { "output": "pair1_low_ramp:Out", "input": "pair1_low_l:In 2" },
          { "output": "pair1_low_ramp:Out", "input": "pair1_low_r:In 2" },
          { "output": "pair1_high_ramp:Out", "input": "pair1_high_l:In 2" },
          { "output": "pair1_high_ramp:Out", "input": "pair1_high_r:In 2" },

          { "output": "pair0_low_l:Out", "input": "mix_l:In 1" },
          { "output": "pair0_high_l:Out", "input": "mix_l:In 2" },
          { "output": "pair1_low_l:Out", "input": "mix_l:In 3" },
          { "output": "pair1_high_l:Out", "input": "mix_l:In 4" },
          { "output": "pair0_low_r:Out", "input": "mix_r:In 1" },
          { "output": "pair0_high_r:Out", "input": "mix_r:In 2" },
          { "output": "pair1_low_r:Out", "input": "mix_r:In 3" },
          { "output": "pair1_high_r:Out", "input": "mix_r:In 4" },
          { "output": "mix_l:Out", "input": "calibration_gain_l:In" },
          { "output": "mix_r:Out", "input": "calibration_gain_r:In" }
        ],
        "inputs": [ "copy_l:In", "copy_r:In" ],
        "outputs": [ "calibration_gain_l:Out", "calibration_gain_r:Out" ],
        "capture.volumes": [
          { "control": "volume_probe:Mult", "min": 0.0, "max": 1.0, "scale": "linear" }
        ]
      },
      "capture.props": {
        "node.name": "]] .. CFG.eq_capture_node_name .. [[",
        "media.class": "Audio/Sink",
        "audio.channels": 2,
        "audio.position": [ "FL", "FR" ]
      },
      "playback.props": {
        "node.target": "]] .. CFG.node_target .. [[",
        "node.passive": true,
        "audio.channels": 2,
        "audio.position": [ "FL", "FR" ]
      ]] .. CFG.tuned_priority_field .. [[
      }
    }
  ]]

  runtime.graph_module = LocalModule("libpipewire-module-filter-chain", args, {})
end

local function set_default_sink()
  if runtime.target_metadata then
    runtime.target_metadata:set(
      0,
      "default.audio.sink",
      "Spa:String:JSON",
      "{\"name\":\"" .. CFG.eq_capture_node_name .. "\"}"
    )
  end
end

runtime.metadata_om = ObjectManager {
  Interest {
    type = "metadata",
    Constraint { "metadata.name", "equals", "settings" },
  },
}

runtime.target_om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "node.name", "equals", CFG.node_target },
  },
}

runtime.metadata_om:connect("object-added", function(_, metadata)
  runtime.target_metadata = metadata
  set_default_sink()
end)

runtime.metadata_om:connect("object-removed", function(_, metadata)
  if runtime.target_metadata == metadata then runtime.target_metadata = nil end
end)

runtime.target_om:connect("object-added", function(_, node)
  Log.info(LOG_PREFIX .. "physical target detected: " .. (node.properties["node.name"] or "<unknown>"))
  set_default_sink()
  if CFG.enforce_physical_volume then force_physical_sink_volume(node) end
  load_modules(node)

  if CFG.enforce_physical_volume then
    node:connect("params-changed", function(changed_node, param_name)
      if param_name == "Props" then force_physical_sink_volume(changed_node) end
    end)
  end
end)

runtime.target_om:connect("object-removed", function()
  unload_modules()
end)

runtime.graph_om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "node.name", "equals", CFG.eq_capture_node_name },
  },
}

runtime.graph_om:connect("object-added", function(_, node)
  runtime.graph_node = node
  Log.info(LOG_PREFIX .. string.format(
    "loudness graph ready: reference %.2f dB SPL at %.1f%% (offset %.3f dB)",
    CFG.reference_spl,
    CFG.reference_volume_linear * 100.0,
    calibration_offset_db
  ))

  local function queue_volume_from_node(changed_node)
    local linear = 1.0
    local muted = false
    for pod in changed_node:iterate_params("Props") do
      local props = parse_props_param(pod)
      local read_linear = read_linear_from_props(props)
      if read_linear ~= nil then linear = read_linear end
      if type(props) == "table" and props.mute == true then muted = true end
      break
    end

    if runtime.last_linear ~= nil
      and math.abs(linear - runtime.last_linear) < EPSILON
      and muted == runtime.last_mute
    then
      return
    end

    runtime.last_linear = linear
    runtime.last_mute = muted
    request_target(target_from_volume(linear, muted))
  end

  queue_volume_from_node(node)
  node:connect("params-changed", function(changed_node, param_name)
    if param_name == "Props" then queue_volume_from_node(changed_node) end
  end)
end)

runtime.graph_om:connect("object-removed", function(_, node)
  if runtime.graph_node == node then unload_modules() end
end)

runtime.target_om:activate()
runtime.metadata_om:activate()
runtime.graph_om:activate()
