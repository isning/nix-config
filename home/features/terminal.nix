{ lib, ... }:
{
  options.features.terminal.enable = lib.mkEnableOption "terminal";
}
