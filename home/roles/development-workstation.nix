{
  imports = [
    ./remote-workstation.nix
    ../features/containers.nix
    ../features/kubernetes.nix
    ../features/kubernetes-ai.nix
    ../features/agent-utilities.nix
    ../base/gui/terminal/kitty.nix
    ../base/gui/terminal/alacritty
    ../base/gui/terminal/foot.nix
  ];
}
