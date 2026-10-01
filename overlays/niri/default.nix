{
  lib,
  niri-spicy,
  niri-spicy-smithay,
  ...
}:

_: prev:
lib.optionalAttrs (prev ? niri) {
  # Correct SDR gamma-control ramps when HDR is always on.
  niri = niri-spicy.packages.${prev.stdenv.hostPlatform.system}.niri.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./hdr-gamma-sdr-compat.patch ];
    nativeBuildInputs = old.nativeBuildInputs ++ [ prev.cmake ];
    buildInputs = old.buildInputs ++ [ prev.shaderc ];
    postPatch = (old.postPatch or "") + ''
      substituteInPlace Cargo.toml --replace-fail '../smithay' '${niri-spicy-smithay}'
    '';
  });
}
