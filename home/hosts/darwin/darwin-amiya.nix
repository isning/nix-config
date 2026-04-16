{ config, ... }:
let
  hostName = "amiya";
in
{
  imports = [ ../../darwin ];

  programs.ssh.matchBlocks."github.com".identityFile =
    "${config.home.homeDirectory}/.ssh/${hostName}";
}
