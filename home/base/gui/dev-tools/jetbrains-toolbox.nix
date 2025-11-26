{ pkgs, nur-isning, ... }:
{
  home.packages = [
    (pkgs.callPackage nur-isning { }).jetbrains-toolbox
  ];
}
