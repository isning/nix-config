{
  imports = [
    ./apps.nix
    ./network-apps.nix
    ../roles/darwin-remote-workstation.nix
    ./nix-core.nix
    ./security.nix
    ./ssh.nix
    ./system.nix
    ./users.nix
    ../base
  ];
}
