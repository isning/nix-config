{
  pkgs,
  name,
  nodeTarget,
  description,

  splAtZeroDbVolume ? null,
  splAtReferenceVolume ? null,
  referenceVolumePercent ? (if splAtZeroDbVolume == null then 95.0 else 100.0),
  standard ? "ISO226-2023",
  mode ? "FFT",
  fftSize ? 4096,
  iirQuality ? "Normal",
  hardClip ? false,
  hardClipRange ? 6.0,
  tunedNodeName ? null,
  tunedPriority ? null,
  hidePhysicalNode ? true,
  enforcePhysicalVolume ? true,
  crossfadeDurationMs ? 35,
}:

assert splAtReferenceVolume != null || splAtZeroDbVolume != null;
assert referenceVolumePercent > 0.0 && referenceVolumePercent <= 100.0;
assert crossfadeDurationMs > 0;
let
  mkPackage = import ./template.nix;
  common = import ./common.nix;
  stdMap = {
    "Flat" = 0;
    "ISO226-2003" = 1;
    "Fletcher-Munson" = 2;
    "Robinson-Dadson" = 3;
    "ISO226-2023" = 4;
  };
  modeMap = {
    "FFT" = 0;
    "IIR" = 1;
  };
  fftMap = {
    "256" = 0;
    "512" = 1;
    "1024" = 2;
    "2048" = 3;
    "4096" = 4;
    "8192" = 5;
    "16384" = 6;
  };
  approxMap = {
    "Fastest" = 0;
    "Low" = 1;
    "Normal" = 2;
    "High" = 3;
    "Best" = 4;
  };

  # LSP's loudness-compensator uses 83 phon as its flat reference.  The legacy
  # zero-dB calibration is an SPL measurement at 100% virtual volume.  It must
  # therefore not inherit the new option's 95% default reference point.
  legacyCalibration = splAtReferenceVolume == null;
  calibrationSpl = if legacyCalibration then splAtZeroDbVolume else splAtReferenceVolume;
  effectiveReferenceVolumePercent = if legacyCalibration then 100.0 else referenceVolumePercent;
  eqCaptureNodeName = common.mkVirtualNodeName nodeTarget "tuned" tunedNodeName;
  tunedPriorityFieldLua =
    if tunedPriority == null then "" else '',"priority.session": ${toString tunedPriority}'';
  hidePhysicalNodeField = common.mkHidePhysicalNodeField "Audio/Sink/Internal" hidePhysicalNode;
  enforcePhysicalVolumeField = common.mkEnforcePhysicalVolumeField "sink" enforcePhysicalVolume;
  luaScriptName = "${name}-logic.lua";
  componentName = "custom.${name}-logic";
  descriptionVal = if description == null then "nil" else builtins.toJSON description;
in
mkPackage {
  inherit pkgs luaScriptName;
  packageName = "sink-processing-pack-${name}";
  registrationFileName = "10-${name}-registration.conf";
  registrationText = common.mkRegistrationText {
    inherit luaScriptName componentName;
    extraConfig = ''

            monitor.alsa.rules = [
              {
                matches = [
                  {
                    node.name = "${nodeTarget}"
                  }
                ]
                actions = {
                  update-props = {
      ${hidePhysicalNodeField}
                    priority.session = 1
      ${enforcePhysicalVolumeField}
                  }
                }
              }
            ]
    '';
  };
  scriptBody = ''
    local CFG = {
      name = ${builtins.toJSON name},
      log_prefix = ${builtins.toJSON "[audio:${name}:speaker] "},
      override_desc = ${descriptionVal},
      reference_spl = ${toString calibrationSpl},
      reference_volume_linear = ${toString (effectiveReferenceVolumePercent / 100.0)},
      crossfade_duration_ms = ${toString crossfadeDurationMs},
      eq_capture_node_name = ${builtins.toJSON eqCaptureNodeName},
      node_target = ${builtins.toJSON nodeTarget},
      std = ${toString stdMap.${standard}},
      mode = ${toString modeMap.${mode}},
      fft = ${toString fftMap.${toString fftSize}},
      approx = ${toString approxMap.${iirQuality}},
      hclip = ${if hardClip then "1" else "0"},
      hcrange = ${toString hardClipRange},
      tuned_priority_field = [=[${tunedPriorityFieldLua}]=],
      enforce_physical_volume = ${if enforcePhysicalVolume then "true" else "false"},
    }

  ''
  + builtins.readFile ./speaker-tuning.lua;
  passthru.requiredLv2Packages = [ pkgs.lsp-plugins ];
}
