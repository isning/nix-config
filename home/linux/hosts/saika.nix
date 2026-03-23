{ config, ... }:
let
  mkSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  programs.ssh.matchBlocks."github.com".identityFile = "${config.home.homeDirectory}/.ssh/saika";

  modules.desktop.nvidia.enable = false;

  xdg.configFile."niri/niri-hardware.kdl".source =
    mkSymlink "${config.home.homeDirectory}/nix-config/hosts/saika/niri-hardware.kdl";
}
