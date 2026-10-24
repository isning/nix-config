{ config, ... }:
let
  hostName = "amiya";
in
{
  imports = [
    ../../darwin
  ];

  roles.remote-workstation.enable = true;

  programs.ssh.settings."github.com".IdentityFile = "${config.home.homeDirectory}/.ssh/${hostName}";
}
