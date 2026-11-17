{ mylib, pkgs, ... }:
{
  imports = mylib.scanPaths ./.;
  home.packages = [ pkgs.android-tools ];
}
