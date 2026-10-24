{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.credentials.enable {

    home.packages = with pkgs; [
      yubico-piv-tool # manage piv on canokey
    ];
  };
}
