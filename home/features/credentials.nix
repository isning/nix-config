{
  config,
  lib,
  pkgs,
  mysecrets,
  ...
}@args:
{
  options.features.credentials.enable = lib.mkEnableOption "credential and encryption tools";

  config = lib.mkIf config.features.credentials.enable (
    lib.mkMerge [
      (import ../base/tui/canokey-tools.nix args)
      (import ../base/tui/encryption args)
      (import ../base/tui/gpg args)
      (import ../base/tui/password-store args)
    ]
  );
}
