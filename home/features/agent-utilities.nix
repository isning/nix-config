{
  lib,
  config,
  pkgs,
  llm-agents,
  open-design,
  ...
}:
{
  options.features.agent-utilities.enable = lib.mkEnableOption "agent-utilities";

  config = lib.mkIf config.features.agent-utilities.enable {

    home.packages =
      (with llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
        codegraph
        rtk
      ])
      ++ [
        (pkgs.writeShellScriptBin "opendesign" ''
          exec ${open-design.packages.${pkgs.stdenv.hostPlatform.system}.daemon}/bin/od "$@"
        '')
        open-design.packages.${pkgs.stdenv.hostPlatform.system}.daemon
      ];
  };
}
