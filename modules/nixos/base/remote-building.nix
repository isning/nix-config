{ ... }:
{
  # No remote builders are registered. Add explicit hosts here when needed.
  nix.distributedBuilds = true;
  nix.buildMachines = [ ];

  # Let future remote builders use their own binary caches.
  nix.extraOptions = ''
    builders-use-substitutes = true
  '';
}
