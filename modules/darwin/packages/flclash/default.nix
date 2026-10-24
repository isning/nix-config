{ pkgs, brew-nix }:
# Metadata from https://github.com/chen08209/homebrew-tap/blob/main/Casks/flclash.rb.
# The author's tap is not included in brew-nix's standard cask index.
(import "${brew-nix}/casks.nix" {
  inherit pkgs;
  brew-api = ./.;
}).flclash
