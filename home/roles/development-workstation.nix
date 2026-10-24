{ config, lib, ... }:
{
  options.roles.development-workstation.enable = lib.mkEnableOption "development-workstation";

  config = lib.mkIf config.roles.development-workstation.enable {
    roles.remote-workstation.enable = lib.mkDefault true;
    features = {
      agents.enable = lib.mkDefault true;
      dev-tools.enable = lib.mkDefault true;
      cloud.enable = lib.mkDefault true;
      language-tooling.enable = lib.mkDefault true;
      credentials.enable = lib.mkDefault true;
      media.enable = lib.mkDefault true;
      containers.enable = lib.mkDefault true;
      kubernetes.enable = lib.mkDefault true;
      kubernetes-ai.enable = lib.mkDefault true;
      agent-utilities.enable = lib.mkDefault true;
      additional-terminals.enable = lib.mkDefault true;
    };
  };
}
