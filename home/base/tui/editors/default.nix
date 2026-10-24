{
  config,
  lib,
  pkgs,
  pkgs-master,
  ...
}@args:
{
  config = lib.mkIf config.features.editors.enable (import ./packages.nix args);
}
