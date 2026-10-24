{ lib, ... }:

_: prev:
lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  obs-studio-plugins = prev.obs-studio-plugins // {
    # FIXME(nixpkgs): Drop this override once Shaderfilter supports
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
  };
}
