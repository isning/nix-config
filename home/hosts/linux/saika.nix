{
  config,
  lib,
  pkgs,
  llm-agents,
  ...
}:
let
  mkSymlink = config.lib.file.mkOutOfStoreSymlink;
  codex = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
  t3code = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code;
in
{
  imports = [ ../../linux/gui.nix ];

  programs.ssh.settings."github.com".IdentityFile = "${config.home.homeDirectory}/.ssh/saika";

  modules.desktop.gaming.enable = true;
  modules.desktop.niri.enable = true;
  modules.desktop.nvidia.enable = true;

  systemd.user.services.codex-remote-control = {
    Unit.Description = "Codex official Remote Control";
    Service = {
      # Run in the foreground under systemd; no managed install or update loop.
      # The local socket is used by the official manual pairing command.
      ExecStart = "${lib.getExe codex} --disable daemon_auto_start app-server --remote-control --managed-daemon --listen unix://";
      WorkingDirectory = "%h";
      Environment = "PATH=${
        lib.concatStringsSep ":" (
          config.home.sessionPath
          ++ [
            "${config.home.homeDirectory}/.local/bin"
            "${config.home.profileDirectory}/bin"
            "/run/wrappers/bin"
            "/run/current-system/sw/bin"
          ]
        )
      }";
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0077";
      LimitCORE = 0;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.t3code = {
    Unit.Description = "T3 Code authenticated LAN server";
    Service = {
      # Desktop runtime mode suppresses startup pairing secrets in the journal;
      # binding a non-loopback address still requires one-time pairing.
      ExecStart = "${lib.getExe t3code} start --mode desktop --no-browser --host 0.0.0.0 --port 3773 --base-dir %h/.t3";
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p %h/.t3"
        "${pkgs.coreutils}/bin/chmod 0700 %h/.t3"
      ];
      WorkingDirectory = "%h";
      # Lingering services start before a login shell populates PATH.
      Environment = "PATH=${
        lib.concatStringsSep ":" (
          config.home.sessionPath
          ++ [
            "${config.home.homeDirectory}/.local/bin"
            "${config.home.profileDirectory}/bin"
            "/run/wrappers/bin"
            "/run/current-system/sw/bin"
          ]
        )
      }";
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0077";
      LimitCORE = 0;
    };
    Install.WantedBy = [ "default.target" ];
  };

  xdg.configFile."niri/niri-hardware.kdl".source =
    mkSymlink "${config.home.homeDirectory}/nix-config/hosts/saika/niri-hardware.kdl";
}
