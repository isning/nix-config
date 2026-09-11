{ config, lib, ... }:
{
  # Upstream recommendation: limit NVIDIA's free buffer pool for niri.
  # https://niri-wm.github.io/niri/Nvidia.html
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-niri.json" =
    lib.mkIf (config.programs.niri.enable && config.hardware.nvidia.enabled)
      {
        text = builtins.toJSON {
          rules = [
            {
              pattern = {
                feature = "procname";
                matches = "niri";
              };
              profile = "niri-limit-free-buffer-pool";
            }
          ];
          profiles = [
            {
              name = "niri-limit-free-buffer-pool";
              settings = [
                {
                  key = "GLVidHeapReuseRatio";
                  value = 0;
                }
              ];
            }
          ];
        };
      };
}
