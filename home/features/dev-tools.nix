{ lib, ... }:
{
  options.features.dev-tools.enable = lib.mkEnableOption "development tools";
}
