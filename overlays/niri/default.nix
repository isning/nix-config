{ lib, ... }:

_: prev:
lib.optionalAttrs (prev ? niri) {
  niri = prev.niri.overrideAttrs (
    old:
    let
      # FIXME(nixpkgs): Drop these patches once PR #3910 and its follow-up are
      # included in the niri version packaged by nixpkgs.
      src = prev.applyPatches {
        name = "niri-${old.version}-with-vram-fix";
        src = old.src;
        patches = (old.patches or [ ]) ++ [
          (prev.fetchpatch {
            url = "https://github.com/niri-wm/niri/pull/3910.patch";
            hash = "sha256-at6S/DeGwdhsJ+zicSFezE71/KbiNo8FMTsZ6hVYN9c=";
          })
          (prev.fetchurl {
            url = "https://github.com/niri-wm/niri/commit/ecb953778c1031d0492cc6bc65429449cb32163c.patch";
            hash = "sha256-en/5I+mNHpEOyse5lzsY1a7VYAfbZkrpPlpJshbm83s=";
          })
        ];
      };
    in
    {
      inherit src;
      patches = [ ];
    }
  );
}
