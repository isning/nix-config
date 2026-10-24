{ myvars, ... }:
{
  mountpoint = "/var/cache/rust";
  buildDirectory = "/var/cache/rust/${myvars.username}/build/{workspace-path-hash}";
  managedRoot = "/var/cache/rust/${myvars.username}/build";
  cacheDirectory = "/var/cache/rust/${myvars.username}/kache";
  cacheServiceEnabled = [ "default.target" ];
  agentBuildDirectories = {
    codex-remote-control = true;
    t3code = true;
  };
  snapshotSubvolumes = [ "@persistent" ];
}
