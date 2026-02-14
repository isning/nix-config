{
  lib,
  pkgs,
  mylib,
  myvars,
  disko,
  ...
}:
#############################################################
#
#  Whitefox - AMD64 Homelab Server (It's actually a whitebox, but I want to call it whitefox :P)
#
#############################################################
let
  hostName = "whitefox"; # Define your hostname.

  coreModule = mylib.genKubeVirtHostModule {
    inherit pkgs hostName;
    inherit (myvars) networking;
  };
  k3sModule = mylib.genK3sServerModule {
    inherit pkgs;
    kubeconfigFile = "/home/${myvars.username}/.kube/config";
    tokenFile = "/run/media/nixos_k3s/kubevirt-k3s-token";
    # the first node in the cluster should be the one to initialize the cluster
    clusterInit = true;
    # use my own domain & kube-vip's virtual IP for the API server
    # so that the API server can always be accessed even if some nodes are down
    masterHost = "kubevirt-cluster-1.isning.moe";
    kubeletExtraArgs = [
      "--cpu-manager-policy=static"
      # https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/
      # we have to reserve some resources for for system daemons running as pods or system services
      # when cpu-manager's static policy is enabled
      # the memory we reserved here is also for the kernel, since kernel's memory is not accounted in pods
      "--system-reserved=cpu=1,memory=2Gi,ephemeral-storage=2Gi"
    ];
    k3sExtraArgs = [
      # IPv4 Private CIDR(full) - 172.16.0.0/12
      # IPv4 Pod     CIDR(full) - fdfd:cafe:00:0000::/64 ~ fdfd:cafe:00:7fff::/64
      # IPv4 Service CIDR(full) - fdfd:cafe:00:8000::/64 ~ fdfd:cafe:00:ffff::/64
      "--cluster-cidr=172.16.0.0/16,fdfd:cafe:00:0001::/64"
      "--service-cidr=172.17.0.0/16,fdfd:cafe:00:8001::/112"
    ];
    nodeLabels = [
      "node-purpose=kubevirt"
    ];
    # kubevirt works well with k3s's flannel,
    # but has issues with cilium(failed to configure vmi network: setup failed, err: pod link (pod6b4853bd4f2) is missing).
    # so we should not disable flannel here.
    disableFlannel = false;
  };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./graphics.nix
    ./preservation.nix
    ./secureboot.nix
    ./tailscale.nix
    coreModule
    k3sModule
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
