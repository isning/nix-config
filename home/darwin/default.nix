{
  myvars,
  ...
}:
{
  home.homeDirectory = "/Users/${myvars.username}";
  imports = [
    ../base/core
    ../base/tui
    ../base/gui
    ../base/home.nix

    ../.
    ./linearmouse.nix
    ./proxy
    ./shell.nix
    ./terminal.nix
  ];

  # enable management of XDG base directories on macOS.
  xdg.enable = true;
}
