{ pkgs, ... }:
{
  boot = {
    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];

    # https://wiki.nixos.org/wiki/Plymouth
    plymouth = {
      enable = true;
    };

    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 0;

    loader.systemd-boot = {
      enable = true;
      # See man loader.conf.5
      rebootForBitlocker = true;

      edk2-uefi-shell.enable = true;
      edk2-uefi-shell.sortKey = "z_edk2";
    };
  };
}
