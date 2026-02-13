{ config, ... }:
{
  services.tailscale.enable = true;
  services.tailscale.extraSetFlags = [ "--netfilter-mode=nodivert" ];
  services.tailscale.extraDaemonFlags = [ "--no-logs-no-support" ];
}
