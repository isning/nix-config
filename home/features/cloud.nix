{ lib, ... }:
{
  options.features.cloud.enable = lib.mkEnableOption "cloud infrastructure tools";
}
