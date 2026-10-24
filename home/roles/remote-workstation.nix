{ config, lib, ... }:
{
  options.roles.remote-workstation.enable = lib.mkEnableOption "remote-workstation";

  config = lib.mkIf config.roles.remote-workstation.enable {
    features = {
      terminal.enable = lib.mkDefault true;
      agents.enable = lib.mkDefault true;
      development-tools.enable = lib.mkDefault true;
      security.enable = lib.mkDefault true;
      desktop-tools.enable = lib.mkDefault true;
    };
  };
}
