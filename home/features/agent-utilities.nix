{
  pkgs,
  llm-agents,
  open-design,
  ...
}:
{
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
}
