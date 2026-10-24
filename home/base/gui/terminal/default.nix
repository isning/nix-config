{
  config,
  lib,
  pkgs,
  ...
}@args:
{
  config = lib.mkMerge [
    (lib.mkIf config.features.terminal.enable (import ./ghostty.nix args))
    (lib.mkIf config.features.additional-terminals.enable (
      lib.mkMerge [
        (import ./kitty.nix args)
        (import ./alacritty args)
        (import ./foot.nix args)
      ]
    ))
  ];
}
