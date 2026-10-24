{ lib, ... }:
_: prev:
let
  releases = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-8vZVXe5QlFwqkKf7eTwghKAMxkWdCKwjBtONkFBkMhs=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-OIVs7mE/buDsV5CZ/JIFuECgtFu3Y/S4+ngtJdk8GO8=";
    };
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-ENCeFGhSqN+Hls9kLKWIchB6fzkbdkfsjMJTzyia8Kk=";
    };
  };
  release = releases.${prev.stdenv.hostPlatform.system};
in
lib.optionalAttrs (builtins.hasAttr prev.stdenv.hostPlatform.system releases) {
  # Use the upstream static release; its source build needs a newer Rust than nixpkgs.
  kache = prev.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "kache";
    version = "1.2.2";
    src = prev.fetchurl {
      url = "https://github.com/kunobi-ninja/kache/releases/download/v${finalAttrs.version}/kache-${release.target}.tar.gz";
      inherit (release) hash;
    };
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      install -Dm755 kache "$out/bin/kache"
      runHook postInstall
    '';
    doInstallCheck = true;
    installCheckPhase = ''
      "$out/bin/kache" --version
    '';
    meta = {
      description = "Content-addressed compiler cache";
      homepage = "https://github.com/kunobi-ninja/kache";
      license = lib.licenses.asl20;
      mainProgram = "kache";
      platforms = builtins.attrNames releases;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  });

  cargo-overstay = prev.rustPlatform.buildRustPackage {
    pname = "cargo-overstay";
    version = "0.4.0";
    src = prev.fetchFromGitHub {
      owner = "lilienblum";
      repo = "cargo-overstay";
      rev = "e1176271e81828b394075d5416695564b1351340";
      hash = "sha256-aBhFjPVgw8gdZeTiKeMxyC2AQzUb+esQO6fC0lK9vEA=";
    };
    cargoHash = "sha256-QdnA1t3RbLWiex5yTjRew0xk+9rmEfyBL05BczWa9xo=";
    patches = [ ./build-dir.patch ];
    meta = {
      description = "Budgeted Cargo build-directory garbage collection";
      homepage = "https://github.com/lilienblum/cargo-overstay";
      license = lib.licenses.mit;
      mainProgram = "cargo-overstay";
      platforms = lib.platforms.unix;
    };
  };
}
