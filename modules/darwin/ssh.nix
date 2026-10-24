{ lib, ... }:
{
  services.openssh.enable = lib.mkDefault false;
}
