{
  nur,
  nuenv,
  colmena,
  rust-overlay,
  ...
}@args:
{
  nixpkgs.overlays = [
    nur.overlays.default
    nuenv.overlays.default
    colmena.overlays.default
    rust-overlay.overlays.default
  ]
  ++ (import ../../overlays args);
}
