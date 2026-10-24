{ lib, ... }:
{
  options.features.desktop-tools.enable = lib.mkEnableOption "desktop-tools";
}
