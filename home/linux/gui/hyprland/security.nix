{
  pkgs,
  ...
}:
let
  package = pkgs.hyprland;
in
{
  # Some desktop components may need a polkit authentication agent to function properly.
  # https://wiki.nixos.org/wiki/Polkit#Authentication_agents
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
  Unit = {
    Description = "polkit-gnome-authentication-agent-1";
    Wants = [ "graphical-session.target" ];
    After = [ "graphical-session.target" ];
  };
  Install = {
    WantedBy = [ "graphical-session.target" ];
  };
  Service = {
    Type = "simple";
    ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    Restart = "on-failure";
    RestartSec = 1;
    TimeoutStopSec = 10;
  };
};
}