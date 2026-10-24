{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rust-cache;
  toml = pkgs.formats.toml { };
  kacheConfig = toml.generate "kache-config.toml" {
    cache = {
      local_store = "${cfg.directory}/kache";
      local_max_size = cfg.maxCacheSize;
      auto_gc = true;
      clean_incremental = true;
      adaptive_incremental = true;
      # Overstay owns build-directory eviction. Keep the two collectors independent.
      auto_clean_orphaned_targets = false;
      auto_clean_idle_targets_days = 0;
      auto_clean_unused_units_days = 0;
      auto_recover_targets = false;
    };
  };
  environment = {
    CARGO_BUILD_BUILD_DIR = "${cfg.directory}/build/{workspace-path-hash}";
    CARGO_OVERSTAY_BUILD_ROOT = "${cfg.directory}/build";
    CARGO_OVERSTAY_CONFIG = "${config.xdg.configHome}/cargo-overstay/config.toml";
    KACHE_CONFIG = toString kacheConfig;
    KACHE_CACHE_DIR = "${cfg.directory}/kache";
    RUSTC_WRAPPER = lib.getExe pkgs.kache;
  };
in
{
  options.programs.rust-cache = {
    enable = lib.mkEnableOption "centralized Rust build directories with Overstay and Kache";
    directory = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.cacheHome}/rust";
      description = "Absolute root for per-workspace build directories and the shared compiler cache.";
    };
    maxTotalSize = lib.mkOption {
      type = lib.types.str;
      default = "75GiB";
      description = "Overstay's combined soft budget for tracked target and build directories.";
    };
    maxBuildSize = lib.mkOption {
      type = lib.types.str;
      default = "20GiB";
      description = "Soft budget for each tracked target or build directory before partial trimming.";
    };
    maxCacheSize = lib.mkOption {
      type = lib.types.str;
      default = "50GiB";
      description = "Kache's local compiler-cache budget, excluding outputs retained by builds.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "programs.rust-cache currently requires Linux user services.";
      }
      {
        assertion = lib.hasPrefix "/" cfg.directory;
        message = "programs.rust-cache.directory must be an absolute path.";
      }
    ];

    home.packages = [
      pkgs.cargo-overstay
      pkgs.kache
    ];
    home.sessionVariables = environment;
    systemd.user.sessionVariables = environment;
    home.sessionPath = lib.mkBefore [ "${config.home.homeDirectory}/.cargo-overstay/bin" ];
    home.file.".cargo-overstay/bin/cargo".source = "${pkgs.cargo-overstay}/bin/cargo-overstay";

    xdg.configFile."kache/config.toml".source = kacheConfig;
    xdg.configFile."cargo-overstay/config.toml".source = toml.generate "overstay-config.toml" {
      max_total_size = cfg.maxTotalSize;
      max_target_size = cfg.maxBuildSize;
    };

    systemd.user.services.kache = {
      Unit = {
        Description = "Kache compiler cache and garbage collector";
        ConditionPathIsDirectory = cfg.directory;
      };
      Service = {
        ExecStart = "${lib.getExe pkgs.kache} daemon run";
        WorkingDirectory = cfg.directory;
        Environment = lib.mapAttrsToList (name: value: "${name}=${value}") environment;
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
