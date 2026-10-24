{
  config,
  lib,
  myvars,
  ...
}:
let
  inherit (myvars) username;
  user = config.users.users.${username};
  directory = "/var/cache/rust/${username}";
in
{
  systemd.tmpfiles.rules = [
    # A subvolume created with root's restrictive umask must remain traversable.
    "d /var/cache/rust 0755 root root -"
  ]
  ++ map (suffix: "d ${directory}${suffix} 0700 ${username} ${user.group} -") [
    ""
    "/build"
    "/kache"
  ];

  preservation.preserveAt."/persistent".users.${username}.directories = [
    ".local/share/cargo-overstay"
  ];
  home-manager.users.${username} =
    { config, ... }:
    {
      programs.rust-cache = {
        enable = true;
        inherit directory;
      };
      # Lingering agents can start before a login shell or environment.d reload.
      systemd.user.services = lib.genAttrs [ "codex-remote-control" "t3code" ] (_: {
        Service.Environment = lib.mkAfter (
          lib.mapAttrsToList (name: value: "${name}=${value}") (
            lib.filterAttrs (
              name: _: lib.hasPrefix "CARGO_" name || lib.hasPrefix "KACHE_" name || name == "RUSTC_WRAPPER"
            ) config.home.sessionVariables
          )
        );
      });
    };
}
