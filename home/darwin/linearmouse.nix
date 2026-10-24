{ ... }:
{
  # This file is managed by Home Manager; edit these settings instead of using the GUI.
  xdg.configFile."linearmouse/linearmouse.json".text = builtins.toJSON {
    schemes = [
      {
        "if".device.category = "mouse";
        scrolling = {
          # Reverse macOS natural scrolling for a traditional mouse wheel.
          reverse.vertical = true;
          distance.vertical = 3;
        };
        pointer = {
          # A starting point with acceleration, not a Windows curve conversion.
          disableAcceleration = false;
          acceleration = 0.5;
          speed = 0.4;
        };
      }
    ];
  };
}
