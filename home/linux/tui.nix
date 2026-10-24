{
  imports = [
    ../base/core
    ../base/tui
    ../base/home.nix

    ../.
    ./base
  ];

  features = {
    dev-tools.enable = true;
    cloud.enable = true;
    editors.enable = true;
    credentials.enable = true;
    containers.enable = true;
    kubernetes.enable = true;
  };
}
