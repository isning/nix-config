{ nuenv, colmena, ... }@args:
{
  nixpkgs.overlays = [
    nuenv.overlays.default
    colmena.overlays.default
  ]
  ++ (import ../../overlays args);
}
