{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.security.enable {

    home.packages = with pkgs; [
      age
      sops
      # rclone
    ];
  };
}
