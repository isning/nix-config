{
  lib,
  pkgs,
  config,
  brew-nix,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.features.media.enable {
      home.packages = with pkgs; [
        (if stdenv.hostPlatform.isLinux then ffmpeg-full else ffmpeg)

        # images
        viu # Terminal image viewer with native support for iTerm and Kitty
        imagemagick
        graphviz
      ];
    })
    (lib.mkIf (config.features.media.recording.enable && pkgs.stdenv.hostPlatform.isDarwin) {
      # The Home Manager plugin wrapper expects Linux's bin/obs layout.
      home.packages = [ brew-nix.packages.${pkgs.stdenv.hostPlatform.system}.obs ];
    })
    (lib.mkIf (config.features.media.recording.enable && pkgs.stdenv.hostPlatform.isLinux) {
      programs = {
        # live streaming
        obs-studio = {
          enable = pkgs.stdenv.hostPlatform.isx86_64;
          plugins = with pkgs.obs-studio-plugins; [
            # screen capture
            wlrobs
            # obs-ndi
            # obs-nvfbc
            obs-teleport
            # obs-hyperion
            # FIXME: Temporaryly disable it since build failure: https://github.com/NixOS/nixpkgs/issues/461403
            # droidcam-obs
            obs-vkcapture
            obs-gstreamer
            input-overlay
            obs-multi-rtmp
            obs-source-clone
            obs-shaderfilter
            obs-source-record
            obs-livesplit-one
            looking-glass-obs
            obs-vintage-filter
            obs-command-source
            obs-move-transition
            obs-backgroundremoval
            # advanced-scene-switcher
            obs-pipewire-audio-capture
            obs-vaapi
            obs-3d-effect
          ];
        };
      };
    })
  ];
}
