{ lib, ... }:
{
  options.features.security.enable = lib.mkEnableOption "security";
}
