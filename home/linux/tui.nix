{
  imports = [
    ../base/core
    ../base/tui
    ../base/home.nix

    ../.
    ./base
  ];

  features = {
    development-tools.enable = true;
    security.enable = true;
    containers.enable = true;
    kubernetes.enable = true;
  };
}
