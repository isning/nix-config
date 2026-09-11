{ lib, ... }:

_: prev:
lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  obs-studio-plugins = prev.obs-studio-plugins // {
    # FIXME(nixpkgs): Drop these overrides once the packaged plugins support
    # OBS 32.2's obs_properties_add_button2 API without local substitutions.
    obs-shaderfilter = prev.obs-studio-plugins.obs-shaderfilter.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace obs-shaderfilter.c \
          --replace-fail 'obs_properties_add_button(props, "reload_effect"' \
            'obs_properties_add_button2(props, "reload_effect"' \
          --replace-fail 'shader_filter_reload_effect_clicked);' \
            'shader_filter_reload_effect_clicked, NULL);'
      '';
    });

    obs-move-transition = prev.obs-studio-plugins.obs-move-transition.overrideAttrs (old: {
      postPatch =
        (old.postPatch or "")
        + lib.concatStringsSep "\n" (
          lib.mapAttrsToList
            (
              file: callbacks:
              ''
                substituteInPlace ${file} \
                  --replace-fail 'obs_properties_add_button(' 'obs_properties_add_button2('
              ''
              + lib.concatMapStrings (callback: ''
                substituteInPlace ${file} \
                  --replace-fail '${callback});' '${callback}, NULL);'
              '') callbacks
            )
            {
              "move-filter.c" = [ "move_filter_start_button" ];
              "move-action-filter.c" = [ "move_filter_start_button" ];
              "move-source-filter.c" = [
                "move_source_get_transform"
                "move_source_relative"
                "move_source_start_button"
              ];
              "move-source-swap-filter.c" = [ "move_source_swap_start_button" ];
              "move-value-filter.c" = [
                "move_value_get_value"
                "move_value_get_values"
              ];
            }
        );
    });
  };
}
