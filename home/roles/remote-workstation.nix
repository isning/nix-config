{ config, lib, ... }:
{
  options.roles.remote-workstation.enable = lib.mkEnableOption "remote-workstation";

  config = lib.mkIf config.roles.remote-workstation.enable {
    features = {
      terminal.enable = lib.mkDefault true;
      agents.enable = lib.mkDefault true;
      dev-tools.enable = lib.mkDefault true;
      cloud.enable = lib.mkDefault true;
      editors.enable = lib.mkDefault true;
      credentials.enable = lib.mkDefault true;
      media.enable = lib.mkDefault true;
    };
  };
}
