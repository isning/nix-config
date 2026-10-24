{
  myvars,
  ...
}:
{
  home.homeDirectory = "/Users/${myvars.username}";
  imports = [
    ../.
    ./linearmouse.nix
    ./proxy
    ./rime-squirrel.nix
    ./shell.nix
    ./terminal.nix
  ];

  # enable management of XDG base directories on macOS.
  xdg.enable = true;
}
