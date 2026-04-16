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
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;
}
