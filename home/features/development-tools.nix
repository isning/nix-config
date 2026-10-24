{ lib, ... }:
{
  options.features.development-tools.enable = lib.mkEnableOption "development-tools";
}
