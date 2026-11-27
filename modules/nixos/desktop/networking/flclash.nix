{
  pkgs,
  config,
  lib,
  myvars,
  ...
}:
let
  package = pkgs.callPackage ../../../../packages/flclash { };
in
{
  environment.systemPackages = [ package ];
  environment.etc."xdg/autostart/com.follow.clash.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=FlClash
    Exec=${package}/bin/flclash
  '';
  networking.firewall.checkReversePath = lib.mkDefault "loose";
  systemd.services.flclash-helper = {
    description = "FlClash privileged core helper";
    wantedBy = [ "multi-user.target" ];
    after = [
      "nftables.service"
      "iptables.service"
    ];
    script = ''
      export FLCLASH_HELPER_OWNER_UID="$(${pkgs.coreutils}/bin/id -u ${lib.escapeShellArg myvars.username})"
      export FLCLASH_HELPER_OWNER_GID="$(${pkgs.coreutils}/bin/id -g ${lib.escapeShellArg myvars.username})"
      exec ${package.bundle}/FlClashHelperService
    '';
    serviceConfig = {
      # The helper creates a 0660 socket using its effective group.
      Group = config.users.users.${myvars.username}.group;
      RuntimeDirectory = "flclash";
      RuntimeDirectoryMode = "0755";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
