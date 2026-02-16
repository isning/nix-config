{
  myvars,
  lib,
  pkgs,
  ...
}:
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
    ./graphics.nix
    ./saika

    ./preservation.nix
    ./secureboot.nix
    ./boot.nix
    ./bitlk-decrypt.nix
  ];

  services.sunshine.enable = lib.mkForce true;

  networking = {
    inherit hostName;

    wireless.iwd.enable = true;

    networkmanager.enable = true;
    networkmanager.wifi.backend = "iwd";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Tuned is enabled at modules/nixos/desktop/power.nix
  services.tuned.ppdSettings.main.default = lib.mkForce "performance";

  systemd.oomd = {
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  boot.extraModprobeConfig = ''
    options snd_sof ipc_type=1
  '';

  services.memfd-ashmem-shim.enable = true;

  # Zram consumes physical memory for compression, which can cause a deadlock and system hang if the model size approaches the physical memory limit.
  zramSwap.enable = lib.mkForce false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
