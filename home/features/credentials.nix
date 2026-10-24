{ lib, ... }:
{
  options.features.credentials.enable = lib.mkEnableOption "credential and encryption tools";
}
