{ pkgs, flclash-tap }:
let
  cask = builtins.readFile "${flclash-tap}/Casks/flclash.rb";
  # Read only the three literals needed from the author's cask, without Ruby.
  read =
    pattern:
    let
      match = builtins.match pattern cask;
    in
    if match == null then
      throw "FlClash tap format changed; update the package's metadata patterns."
    else
      builtins.head match;
  version = read ''.*version "([^"]+)".*'';
  arm = pkgs.stdenv.hostPlatform.isAarch64;
  arch = if arm then "arm64" else "amd64";
  sha256 =
    if arm then read ''.*sha256 arm: *"([0-9a-f]+)".*'' else read ''.*intel: *"([0-9a-f]+)".*'';
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "flclash";
  inherit version;
  src = pkgs.fetchurl {
    url = "https://github.com/chen08209/FlClash/releases/download/v${version}/FlClash-${version}-macos-${arch}.dmg";
    inherit sha256;
  };
  nativeBuildInputs = [ pkgs._7zz ];
  sourceRoot = "FlClash/FlClash.app";
  unpackPhase = ''
    7zz x -snld20 "$src"
  '';
  installPhase = ''
    mkdir -p "$out/Applications"
    cp -R . "$out/Applications/FlClash.app"
  '';
  # Preserve the vendor bundle and its code signature.
  dontFixup = true;
  meta = {
    description = "Multi-platform proxy client based on ClashMeta";
    homepage = "https://github.com/chen08209/FlClash";
    platforms = pkgs.lib.platforms.darwin;
  };
}
