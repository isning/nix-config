{ mylib, ... }:
{
  imports = [
    ./base/home.nix
    ./base/core
    ./base/tui
    ./base/gui
  ]
  ++ mylib.scanPaths ./features
  ++ mylib.scanPaths ./roles;
}
