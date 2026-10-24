{
  config,
  lib,
  pkgs,
  pkgs-master,
  ...
}@args:
{
  config = lib.mkIf config.features.language-tooling.enable (import ./packages.nix args);
}
