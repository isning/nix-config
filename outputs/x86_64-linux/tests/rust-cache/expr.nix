{
  outputs,
  myvars,
  lib,
  ...
}:
let
  system = outputs.nixosConfigurations.saika-niri.config;
  home = system.home-manager.users.${myvars.username};
  volume = system.disko.devices.disk.s790-4t.content.partitions.root.content.content.subvolumes;
in
{
  mountpoint = volume."@rust-cache".mountpoint;
  buildDirectory = home.home.sessionVariables.CARGO_BUILD_BUILD_DIR;
  managedRoot = home.home.sessionVariables.CARGO_OVERSTAY_BUILD_ROOT;
  cacheDirectory = home.home.sessionVariables.KACHE_CACHE_DIR;
  cacheServiceEnabled = home.systemd.user.services.kache.Install.WantedBy;
  agentBuildDirectories = lib.genAttrs [ "codex-remote-control" "t3code" ] (
    name:
    builtins.elem "CARGO_BUILD_BUILD_DIR=${home.home.sessionVariables.CARGO_BUILD_BUILD_DIR}" (
      home.systemd.user.services.${name}.Service.Environment
    )
  );
  snapshotSubvolumes = builtins.attrNames (
    system.services.btrbk.instances.btrbk.settings.volume."/btr_pool".subvolume
  );
}
