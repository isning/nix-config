{ config, lib, ... }:
{
  boot.extraModprobeConfig = "options kvm_amd nested=1"; # for amd cpu
  boot.kernelModules = [
    "kvm-amd"
    "vfio-pci"
  ];
}
