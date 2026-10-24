_:
#############################################################
#
#  Amiya - MacBook Air 2025 13-inch M4 16G.
#
#############################################################
let
  hostname = "amiya";
in
{
  imports = [ ../../modules/roles/darwin-remote-workstation.nix ];

  networking.hostName = hostname;
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;
}
