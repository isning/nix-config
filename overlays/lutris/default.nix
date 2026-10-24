{ lib, pkgs-master, ... }:

_: prev:
lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  # FIXME(nixpkgs): Remove once the primary input provides cached Lutris dependencies
  # without pyrate-limiter's timing-sensitive test_factory_leak[create_mp_bucket] failure.
  lutris-unwrapped = pkgs-master.lutris-unwrapped;
}
