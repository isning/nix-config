{ config, ... }:
{
  services.tailscale.enable = true;
  services.tailscale.extraSetFlags = [
    "--netfilter-mode=nodivert"
    "--advertise-exit-node"
    "--advertise-routes=192.168.1.0/24,192.168.2.0/24,192.168.3.0/24,192.168.4.0/24"
  ];
  services.tailscale.extraDaemonFlags = [ "--no-logs-no-support" ];
}
