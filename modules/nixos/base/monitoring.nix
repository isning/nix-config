{
  config,
  lib,
  pkgs,
  ...
}:
let
  amdGpuEnabled =
    lib.attrByPath [ "hardware" "amdgpu" "initrd" "enable" ] false config
    || lib.attrByPath [ "hardware" "amdgpu" "opencl" "enable" ] false config;
  intelGpuEnabled = lib.attrByPath [ "hardware" "intelgpu" "driver" ] null config != null;
  nvidiaGpuEnabled = lib.attrByPath [ "hardware" "nvidia" "enabled" ] false config;

  enabledGpuTypes =
    lib.optional amdGpuEnabled "amd"
    ++ lib.optional intelGpuEnabled "intel"
    ++ lib.optional nvidiaGpuEnabled "nvidia";

  nvtopPackage =
    if enabledGpuTypes == [ ] then
      null
    else if builtins.length enabledGpuTypes == 1 then
      pkgs.nvtopPackages.${builtins.head enabledGpuTypes}
    else
      pkgs.nvtopPackages.full;
in
{
  # btop enables GPU collectors at compile time, but NVIDIA and AMD also need
  # their driver libraries added to its runtime search path.
  nixpkgs.overlays = lib.optional (amdGpuEnabled || nvidiaGpuEnabled) (
    _: prev: {
      btop = prev.btop.override {
        cudaSupport = nvidiaGpuEnabled;
        rocmSupport = amdGpuEnabled;
      };
    }
  );

  security.wrappers = lib.mkIf intelGpuEnabled {
    btop = {
      source = lib.getExe pkgs.btop;
      owner = "root";
      group = "root";
      capabilities = "cap_perfmon,cap_dac_read_search+ep";
    };
    nvtop = {
      source = lib.getExe nvtopPackage;
      owner = "root";
      group = "root";
      capabilities = "cap_perfmon+ep";
    };
  };

  environment.systemPackages = lib.optional (nvtopPackage != null) nvtopPackage;

  # enable the node exporter on all nixos hosts
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/services/monitoring/prometheus/exporters/node.nix
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9100;
    # There're already a lot of collectors enabled by default
    # https://github.com/prometheus/node_exporter?tab=readme-ov-file#enabled-by-default
    enabledCollectors = [
      "systemd"
      "logind"
    ];

    # use either enabledCollectors or disabledCollectors
    # disabledCollectors = [];

    extraFlags = [
      # Exclude pseudo/ephemeral FS:
      #   - /proc, /sys: kernel pseudo-FS, always size 0
      #   - /dev: tmpfs/devices, not meaningful for disk usage
      # Exclude system/runtime tmp dirs:
      #   - /run/credentials/... → systemd service secrets (strict perms)
      #   - /run/user/... → per-user tmpfs (0700, IPC sockets, not storage)
      # Exclude container/runtime mounts:
      #   - /var/lib/docker/, /var/lib/containers/ and /var/lib/kubelet/ → too much overlay/tmpfs mounts,
      #     often EACCES (strict perms, namespaces) → false alerts
      # Exclude user bind mounts:
      #   - /home/ryan/.+ → bind-mounted from /persistent (NixOS tmpfs-root setup),
      #     monitoring /persistent is sufficient
      # Note: ^(/|/persistent/) prefix ensures both root-level and
      #       /persistent-prefixed paths (used in NixOS's tmpfs-as-root setup) are excluded.
      "--collector.filesystem.mount-points-exclude=^(/|/persistent/)(dev|proc|sys|run/credentials/.+|run/user/.+|var/lib/docker/.+|var/lib/containers/.+|var/lib/kubelet/.+|home/ryan/.+)($|/)"
    ];
  };
}
