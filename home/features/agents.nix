{
  lib,
  config,
  pkgs,
  llm-agents,
  ...
}:
let
  upstreamCodex = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
  # Keep CLI sessions in-process, matching nixpkgs#567051. The dedicated
  # Remote Control service runs app-server directly without a self-updating install.
  codexPackage = pkgs.symlinkJoin {
    name = "codex-${upstreamCodex.version}";
    inherit (upstreamCodex) version meta;
    paths = [ upstreamCodex ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/codex --add-flags "--disable daemon_auto_start"
    '';
  };
in
{
  options.features.agents.enable = lib.mkEnableOption "agents";

  config = lib.mkIf config.features.agents.enable {

    home.packages = [
      codexPackage
    ]
    ++ (with llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      # Agents
      # cursor-cli
      claude-code
      gemini-cli
      opencode
      t3code
    ]);
  };
}
