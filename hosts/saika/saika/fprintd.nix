{ pkgs, ... }:
{
  # Fingerprint sensor
  # https://wiki.archlinux.org/title/Fprint
  # https://wiki.nixos.org/wiki/Fingerprint_scanner
  services.fprintd.enable = true;
}
