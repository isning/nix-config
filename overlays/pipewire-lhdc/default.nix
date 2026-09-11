{ lib, ... }:

final: prev:
lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  liblhdcv5 = final.callPackage ./liblhdcv5.nix { };

  # FIXME(nixpkgs): Drop this package after WirePlumber includes
  # https://github.com/PipeWire/wireplumber/commit/7c3bf214b7026ff7bb32e94d7489dcadbc4580b5
  # in a stable nixpkgs release (expected after 0.5.17).
  wireplumber-bluez-fix =
    (prev.wireplumber.override { pipewire = final.pipewire-lhdc; }).overrideAttrs
      (old: {
        patches =
          (old.patches or [ ])
          ++ lib.optionals (lib.versionOlder old.version "0.5.18") [
            (prev.fetchpatch {
              url = "https://github.com/PipeWire/wireplumber/commit/7c3bf214b7026ff7bb32e94d7489dcadbc4580b5.patch";
              hash = "sha256-Jcwx3ZCO1ri/2NmVmnsJRkgzTU57PtHp1pF0f8u2uXw=";
            })
          ];
      });

  # FIXME(nixpkgs): Replace this override with nixpkgs' PipeWire package once
  # it enables LHDC and packages liblhdcv5. Track package availability with:
  #   nix search nixpkgs lhdc
  # The patches are the complete upstream LHDC v5 series missing from 1.6.8.
  pipewire-lhdc = prev.pipewire.overrideAttrs (old: {
    pname = "pipewire-lhdc";
    patches = (old.patches or [ ]) ++ [
      (prev.fetchpatch {
        url = "https://github.com/PipeWire/pipewire/commit/eee19d3ed5ea.patch";
        hash = "sha256-P8Lgowi2p6i4UosVXSGmrzAIgR8nHJMXOlZuiHaG0f4=";
      })
      (prev.fetchpatch {
        url = "https://github.com/PipeWire/pipewire/commit/641631fa6ed0.patch";
        hash = "sha256-GCug0n0y/C9xpgmQRHkXhbgOvGsDgCFLelAFsiQ+Sa4=";
      })
      (prev.fetchpatch {
        url = "https://github.com/PipeWire/pipewire/commit/08a92f017e51.patch";
        hash = "sha256-qrXIaiq+Is0cWWVqVKUPSkUxnBAY1lR6jZmMvmI2TLY=";
      })
      (prev.fetchpatch {
        url = "https://github.com/PipeWire/pipewire/commit/f300f5992571.patch";
        hash = "sha256-wnTjDskXUNr8WcfpwZzEGRzU7iJh2IDGp7+QqMoxY1c=";
      })
    ];
    buildInputs = (old.buildInputs or [ ]) ++ [ final.liblhdcv5 ];
    mesonFlags = (old.mesonFlags or [ ]) ++ [ (lib.mesonEnable "bluez5-codec-lhdc" true) ];
  });
}
