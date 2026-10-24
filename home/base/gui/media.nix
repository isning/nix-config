{
  lib,
  pkgs,
  config,
  ...
}:
# processing audio/video
{
  config = lib.mkIf config.features.desktop-tools.enable {

    home.packages = with pkgs; [
      ffmpeg-full

      # images
      viu # Terminal image viewer with native support for iTerm and Kitty
      imagemagick
      graphviz
    ];
  };
}
