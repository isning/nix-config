{ lib, ... }:
{
  options.features.language-tooling.enable = lib.mkEnableOption "local language runtimes, compilers, language servers, and formatters";
}
