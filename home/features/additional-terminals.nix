{ lib, ... }:
{
  options.features.additional-terminals.enable = lib.mkEnableOption "additional-terminals";
}
