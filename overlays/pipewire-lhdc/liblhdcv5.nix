{
  lib,
  stdenv,
  fetchFromGitHub,
  cargo,
  rustPlatform,
  rustc,
}:

stdenv.mkDerivation (finalAttrs: {
  # FIXME(nixpkgs): Remove this local package when liblhdcv5 is available in
  # nixpkgs and consume that package from the PipeWire override instead.
  pname = "liblhdcv5";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "DBeidachazi";
    repo = "liblhdcv5";
    rev = "08b9ce51420552299476d323af3f2f69db1889e4";
    hash = "sha256-Ba2/zfcfmP0SRE7lYUOeEOcq3d8kXJeXdzhmFTMnwNI=";
  };

  cargoRoot = "aosp";
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src cargoRoot;
    hash = "sha256-vnNZ6gTW5zWEPpegBEu/8Jt1edZKJ/PhPT0XI664Ub8=";
  };

  postPatch = ''
    substituteInPlace lhdcv5.pc.in \
      --replace-fail "prefix=/usr" "prefix=$out"
  '';

  nativeBuildInputs = [
    cargo
    rustc
    rustPlatform.cargoSetupHook
  ];

  makeFlags = [
    "PREFIX=$(out)"
    "VERSION=${finalAttrs.version}"
  ];

  meta = {
    description = "AOSP LHDC v5 Bluetooth encoder library for Linux";
    homepage = "https://github.com/DBeidachazi/liblhdcv5";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
})
