{
  lib,
  niri-spicy,
  niri-spicy-smithay,
  ...
}:

_: prev:
lib.optionalAttrs (prev ? niri) {
  niri = niri-spicy.packages.${prev.stdenv.hostPlatform.system}.niri.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ prev.cmake ];
    buildInputs = old.buildInputs ++ [ prev.shaderc ];
    postPatch = (old.postPatch or "") + ''
      substituteInPlace Cargo.toml --replace-fail '../smithay' '${niri-spicy-smithay}'
    '';
  });
}
