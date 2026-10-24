{
  config,
  lib,
  pkgs,
  myvars,
  flclash-tap,
  ...
}:
let
  flclash = pkgs.callPackage ./packages/flclash { inherit flclash-tap; };
  bundleRoot = "/Library/Application Support/nix-config/flclash";
  versionDir = "${bundleRoot}/${builtins.baseNameOf (toString flclash)}";
  bundle = "${versionDir}/FlClash.app";
  deployFlclash = pkgs.writeShellScript "deploy-flclash" ''
    set -eu
    app=/Applications/FlClash.app
    if [ -L "$app" ]; then
      case "$(/usr/bin/readlink "$app")" in
        '${bundleRoot}/'*/FlClash.app) ;;
        *) echo "Refusing to replace unmanaged $app; move it aside first." >&2; exit 1 ;;
      esac
    elif [ -e "$app" ]; then
      echo "Refusing to replace unmanaged $app; move it aside first." >&2
      exit 1
    fi

    # macOS TUN needs a root:admin, setuid Core, which cannot live in the Nix store.
    # Copy the unmodified signed bundle to a root-owned, versioned location.
    /usr/bin/install -d -o root -g wheel -m 0755 '${bundleRoot}'
    if [ ! -f '${versionDir}/.ready' ]; then
      /usr/bin/install -d -o root -g wheel -m 0755 '${versionDir}'
      /usr/bin/ditto --noqtn '${flclash}/Applications/FlClash.app' '${bundle}'
      /usr/sbin/chown -R root:wheel '${versionDir}'
      /bin/chmod -R go-w '${versionDir}'
      /usr/sbin/chown root:admin '${bundle}/Contents/MacOS/FlClashCore'
      /bin/chmod 4750 '${bundle}/Contents/MacOS/FlClashCore'
      /usr/bin/codesign --verify --deep --strict '${bundle}'
      /usr/bin/touch '${versionDir}/.ready'
    fi

    if [ ! -L "$app" ] || [ "$(/usr/bin/readlink "$app")" != '${bundle}' ]; then
      if [ -L "$app" ]; then ${pkgs.coreutils}/bin/unlink "$app"; fi
      /bin/ln -s '${bundle}' "$app"
    fi
  '';
in
{
  config = lib.mkIf config.features.desktop-apps.enable {
    system.activationScripts.postActivation.text = ''
      ${deployFlclash}
    '';

    # Like Wireshark's ChmodBPF helper, pre-create devices before granting access.
    # Restrict the grant to the configured workstation user, without a new group.
    launchd.daemons.wireshark-bpf = {
      script = ''
        set -eu
        max=$(/usr/sbin/sysctl -n debug.bpf_maxdevices)
        if [ "$max" -gt 256 ]; then max=256; fi
        for ((i=0; i<max; i++)); do
          read -r -n 0 < "/dev/bpf$i" > /dev/null 2>&1 || true
        done
        /usr/sbin/chown ${lib.escapeShellArg myvars.username} /dev/bpf[0-9]*
        /bin/chmod u+rw /dev/bpf[0-9]*
      '';
      serviceConfig.RunAtLoad = true;
    };
  };
}
