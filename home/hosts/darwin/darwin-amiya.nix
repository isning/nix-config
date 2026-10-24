{ config, ... }:
let
  hostName = "amiya";
in
{
  imports = [
    ../../darwin
    ../../roles/remote-workstation.nix
  ];

  programs.ssh.settings."github.com".IdentityFile = "${config.home.homeDirectory}/.ssh/${hostName}";
}
