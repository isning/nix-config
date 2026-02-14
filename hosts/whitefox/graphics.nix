{ config, lib, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # ===============================================================================================
  # for AMD GPU
  # https://wiki.nixos.org/wiki/AMD_GPU
  # https://wiki.archlinux.org/title/AMDGPU
  # ===============================================================================================
  hardware.amdgpu.initrd.enable = true;
  # Enable OpenCL
  hardware.amdgpu.opencl.enable = true;
}
