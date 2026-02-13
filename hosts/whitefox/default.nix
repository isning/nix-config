{
  myvars,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  Whitefox - AMD64 Homelab Server (It's actually a whitebox, but I want to call it whitefox :P)
#
#############################################################
let
  hostName = "whitefox";
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./graphics.nix
    ./preservation.nix
    ./secureboot.nix
  ];

  networking = {
    inherit hostName;
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
