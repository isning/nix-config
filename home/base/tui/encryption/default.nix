{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.credentials.enable {

    home.packages = with pkgs; [
      age
      sops
      # rclone
    ];
  };
}
