{ lib, pkgs, ... }:
{
  # Workaround from: https://discourse.nixos.org/t/how-to-enable-num-lock-for-the-disk-decryption-passphrase/40625/4
  # Enable num lock early on boot
  boot.initrd.systemd = {
    storePaths = [
      "${pkgs.kbd}/bin/setleds"
    ];
    services.numlockon-initrd = {
      description = "Enable NumLock at startup for stage 1";
      wantedBy = [ "initrd.target" ];
      before = [ "initrd-root-device.target" ];
      unitConfig = {
        DefaultDependencies = false;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.kbd}/bin/setleds -D +num";
        StandardInput = "tty";
        TTYPath = "/dev/tty0";
      };
    };
  };
}
