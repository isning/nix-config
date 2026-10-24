{ lib, ... }:
{
  options.features.editors.enable = lib.mkEnableOption "editor language tooling";
}
