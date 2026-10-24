{
  config,
  lib,
  pkgs,
  pkgs-master,
  nur-isning,
  ...
}@args:
{
  config = lib.mkIf config.features.dev-tools.enable (
    lib.mkMerge [
      (import ./misc.nix args)
      (import ./jetbrains-toolbox.nix args)
    ]
  );
}
