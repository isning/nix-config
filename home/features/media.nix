{ lib, ... }:
{
  options.features.media.enable = lib.mkEnableOption "media tools";
}
