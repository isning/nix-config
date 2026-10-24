{
  figma-linux-next,
  pkgs,
  ...
}:
let
  packageJson = builtins.fromJSON (
    builtins.readFile ../../../packages/figma-console-mcp/package.json
  );
  figma-console-mcp-package = pkgs.buildNpmPackage {
    pname = "figma-console-mcp";
    version = packageJson.dependencies.figma-console-mcp;

    src = ../../../packages/figma-console-mcp;
    npmDepsHash = "sha256-4oJoq+wtQTyJ7ZZ+doWxpYJgwGTw44KtmF7numHun1I=";
    dontNpmBuild = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postInstall = ''
      local package_dir="$out/lib/node_modules/figma-console-mcp-nix/node_modules/figma-console-mcp"
      substituteInPlace "$package_dir/dist/local.js" \
        --replace-fail \
          'join(homedir(), ".figma-console-mcp", "plugin")' \
          'join(process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state"), "figma-console-mcp", "plugin")'

      mkdir -p "$out/bin"
      makeWrapper ${pkgs.nodejs}/bin/node "$out/bin/figma-console-mcp" \
        --add-flags "$package_dir/dist/local.js"
    '';

    meta = {
      description = "MCP server bridging AI assistants with Figma Desktop";
      homepage = "https://github.com/southleft/figma-console-mcp";
      license = pkgs.lib.licenses.mit;
      mainProgram = "figma-console-mcp";
    };
  };
in
{
  imports = [ figma-linux-next.nixosModules.default ];

  programs.figma-linux-next.enable = true;
  environment.systemPackages = [ figma-console-mcp-package ];
}
