{ pkgs-master, ... }:

_: _: {
  # FIXME(nixpkgs): Remove once the primary nixpkgs input provides a cached SQLFluff
  # with diff-cover >= 10.6.0, which fixes the HTML snapshot test failures.
  sqlfluff = pkgs-master.sqlfluff;
}
