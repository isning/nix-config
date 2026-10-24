{ pkgs }:
pkgs.runCommand "rust-cache-check"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.rust-bin.stable.latest.minimal
      pkgs.stdenv.cc
      pkgs.cargo-overstay
      pkgs.kache
    ];
  }
  ''
    python3 ${./check.py} --overstay ${pkgs.cargo-overstay}/bin/cargo-overstay --kache ${pkgs.kache}/bin/kache
    mkdir -p "$out"
    echo passed > "$out/result"
  ''
