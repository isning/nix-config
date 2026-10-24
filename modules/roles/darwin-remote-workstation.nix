{ config, lib, ... }:
{
  options.roles.remote-workstation.enable = lib.mkEnableOption "remote workstation";

  config = lib.mkIf config.roles.remote-workstation.enable {
    features.desktop-apps.enable = lib.mkDefault true;
    services.openssh.enable = true;
  };
}
