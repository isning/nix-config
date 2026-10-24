{
  lib,
  config,
  pkgs,
  llm-agents,
  ...
}:
{
  options.features.agents.enable = lib.mkEnableOption "agents";

  config = lib.mkIf config.features.agents.enable {

    home.packages = (
      with llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      [
        # Agents
        codex
        # cursor-cli
        claude-code
        gemini-cli
        opencode
      ]
    );
  };
}
