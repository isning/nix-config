{
  lib,
  pkgs,
  config,
  ...
}:
# processing audio/video
{
  config = lib.mkIf config.features.media.enable {

    home.packages = with pkgs; [
      (if stdenv.hostPlatform.isLinux then ffmpeg-full else ffmpeg)

      # images
      viu # Terminal image viewer with native support for iTerm and Kitty
      imagemagick
      graphviz
    ];
  };
}
