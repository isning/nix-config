{
  imports = [
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
