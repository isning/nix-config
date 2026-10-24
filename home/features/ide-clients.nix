{ lib, ... }:
{
  options.features.ide-clients.enable = lib.mkEnableOption "IDE clients for local and remote development";
}
