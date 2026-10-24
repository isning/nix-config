{
  config,
  lib,
  pkgs,
  pkgs-master,
  nur-isning,
  ...
}@args:
{
  config = lib.mkMerge [
    (lib.mkIf config.features.dev-tools.enable (import ./misc.nix args))
    (lib.mkIf config.features.ide-clients.enable (import ./jetbrains-toolbox.nix args))
  ];
}
