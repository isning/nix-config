{ lib, pkgs, ... }:
let
  display = pkgs.writeShellApplication {
    name = "sunshine-niri";
    runtimeInputs = [ pkgs.niri ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./sunshine-niri.py} "$@"
    '';
  };
in
{
  environment.systemPackages = [ display ];
  system.build.sunshine-niri = display;

  system.build.sunshine-niri-tests =
    pkgs.runCommand "sunshine-niri-tests"
      {
        nativeBuildInputs = [ pkgs.python3 ];
      }
      ''
        cp ${./sunshine-niri.py} sunshine_niri.py
        cp ${./sunshine-niri-tests.py} test_sunshine_niri.py
        python3 -m unittest -v
        touch "$out"
      '';

  services.sunshine = {
    # wlr capture does not need the privileged DRM/KMS wrapper.
    capSysAdmin = lib.mkForce false;
    settings = {
      port = 27989;
      capture = "wlr";
      encoder = "nvenc";
      # wlr selects this output during virtual sessions. With it removed by undo, the
      # ordinary Desktop entry uses wlr's fallback to the first connected display.
      output_name = "sunshine";
      # The virtual-output patch currently provides SDR outputs.
      hevc_mode = 2;
      av1_mode = 2;
    };
    applications.apps = [
      {
        name = "Desktop";
      }
      {
        name = "Virtual Desktop";
        "prep-cmd" = [
          {
            do = "${lib.getExe display} start";
            undo = "${lib.getExe display} stop";
          }
        ];
      }
    ];
  };

  systemd.user.services.sunshine.serviceConfig = {
    # Recover interrupted sessions before starting, and on service exit/crash.
    ExecStartPre = "${lib.getExe display} stop";
    ExecStopPost = "${lib.getExe display} stop";
    TimeoutStopSec = 60;
  };
}
