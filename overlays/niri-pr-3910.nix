{ lib, ... }:

_: prev:
lib.optionalAttrs (prev ? niri) {
  niri = prev.niri.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (prev.fetchpatch {
        url = "https://github.com/niri-wm/niri/pull/3910.patch";
        hash = "sha256-at6S/DeGwdhsJ+zicSFezE71/KbiNo8FMTsZ6hVYN9c=";
      })
    ];
  });
}
