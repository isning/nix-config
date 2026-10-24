{
  outputs,
  myvars,
  lib,
  ...
}:
let
  system = outputs.darwinConfigurations.amiya.config;
  home = system.home-manager.users.${myvars.username};
  overridden =
    (outputs.darwinConfigurations.amiya.extendModules {
      modules = [
        {
          home-manager.users.${myvars.username}.features = {
            agents.enable = false;
            kubernetes.enable = true;
            dev-tools.enable = false;
            ide-clients.enable = false;
            media.enable = false;
            media.recording.enable = false;
            cloud.enable = true;
            language-tooling.enable = true;
          };
        }
      ];
    }).config.home-manager.users.${myvars.username};
  packages = map (p: p.pname or p.name) home.home.packages;
  systemPackages = map (p: p.pname or p.name) system.environment.systemPackages;
in
{
  warnings = system.warnings ++ home.warnings;
  role = home.roles.remote-workstation.enable;
  languageTooling = home.features.language-tooling.enable;
  groupOverrides =
    !overridden.features.dev-tools.enable
    && !overridden.features.ide-clients.enable
    && overridden.features.cloud.enable
    && overridden.features.language-tooling.enable
    && !(builtins.any (p: lib.hasPrefix "jetbrains-toolbox" p.name) overridden.home.packages);
  featureOverrides =
    !overridden.features.agents.enable
    && overridden.programs.k9s.enable
    && !overridden.features.containers.enable;
  ssh = system.services.openssh.enable;
  moonlight = builtins.elem "moonlight" systemPackages;
  obs = home.features.media.recording.enable && builtins.elem "obs" packages;
  recordingOverride = !(builtins.any (p: (p.pname or p.name) == "obs") overridden.home.packages);
  wireshark = builtins.elem "wireshark-app" systemPackages;
  homebrew = system.homebrew.enable;
  brewCasks = map (cask: cask.name) system.homebrew.casks;
  bpfAccess = system.launchd.daemons.wireshark-bpf.serviceConfig.RunAtLoad;
  ideClients = builtins.elem "jetbrains-toolbox" packages;
  localDevelopment = lib.intersectLists [
    "go"
    "rust-default"
    "zulu-ca-jdk"
    "nodejs"
    "bun"
    "insomnia"
    "terraform"
    "terraformer"
    "devbox"
    "huggingface-hub"
    "mitmproxy"
    "ffmpeg"
    "codex"
    "claude-code"
    "gemini-cli"
    "opencode"
    "pass-env"
    "yubico-piv-tool"
    "caddy"
    "clash-meta"
  ] (packages ++ systemPackages);
  localDevelopmentCasks = lib.intersectLists [
    "miniforge"
    "macfuse"
  ] (map (cask: cask.name) system.homebrew.casks);
  ghostty = home.programs.ghostty.enable;
  kitty = home.programs.kitty.enable;
  alacritty = home.programs.alacritty.enable;
  kubernetes = home.programs.k9s.enable || home.programs.kubecolor.enable;
  optionalTools = lib.intersectLists [
    "codegraph"
    "rtk"
    "open-design"
    "opendesign"
    "kubectl"
    "k8sgpt"
    "kubectl-ai"
    "podman-compose"
    "skopeo"
  ] packages;
}
