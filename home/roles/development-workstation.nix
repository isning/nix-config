{ config, lib, ... }:
{
  options.roles.development-workstation.enable = lib.mkEnableOption "development-workstation";

  config = lib.mkIf config.roles.development-workstation.enable {
    roles.remote-workstation.enable = lib.mkDefault true;
    features = {
      containers.enable = lib.mkDefault true;
      kubernetes.enable = lib.mkDefault true;
      kubernetes-ai.enable = lib.mkDefault true;
      agent-utilities.enable = lib.mkDefault true;
      additional-terminals.enable = lib.mkDefault true;
    };
  };
}
