{ config, lib, ... }:
{
  options.roles.remote-workstation.enable = lib.mkEnableOption "remote-workstation";

  config = lib.mkIf config.roles.remote-workstation.enable {
    features = {
      terminal.enable = lib.mkDefault true;
      ide-clients.enable = lib.mkDefault true;
      media.recording.enable = lib.mkDefault true;
    };
  };
}
