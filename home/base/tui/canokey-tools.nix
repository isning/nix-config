{ pkgs, ... }:
{
  home.packages = with pkgs; [
    yubico-piv-tool # manage piv on canokey
  ];
}
