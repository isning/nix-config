{
  lib,
  config,
  pkgs-master,
  nur-isning,
  ...
}:
{
  config = lib.mkIf config.features.desktop-tools.enable {

    home.packages = [
      pkgs-master.jetbrains-toolbox
    ];
  };
}
