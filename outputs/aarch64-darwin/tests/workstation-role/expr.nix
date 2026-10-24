{
  outputs,
  myvars,
  lib,
  ...
}:
let
  system = outputs.darwinConfigurations.amiya.config;
  home = system.home-manager.users.${myvars.username};
  packages = map (p: p.pname or p.name) home.home.packages;
in
{
  ssh = system.services.openssh.enable;
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
