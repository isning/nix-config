{ myvars, lib, ... }:
#############################################################
#
#  Saika
#
#############################################################
let
  hostName = "saika"; # Define your hostname.
in
{
  imports = [
    ./netdev-mount.nix
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./nvidia.nix
    ./saika

    ./preservation.nix
    ./secureboot.nix
    ./boot.nix
    ./bitlk-decrypt.nix
  ];

  services.sunshine.enable = lib.mkForce true;

  networking = {
    inherit hostName;

    networkmanager.enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # TLP is enabled by default with the nixos-hardware module.
  # It is disabling my bluetooth on boot by blocking it via rfkill, so disable it.
  # TODO: remove this when nixos-hardware replaces TLP with tuned.
  # See https://github.com/NixOS/nixos-hardware/pull/1474
  services.tlp.enable = false;
  services.tuned.enable = true;

  systemd.oomd = {
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
