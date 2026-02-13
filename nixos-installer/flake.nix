{
  description = "NixOS configuration of Ryan Yin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    preservation.url = "github:nix-community/preservation";
    nuenv.url = "github:DeterminateSystems/nuenv";
  };

  outputs =
    inputs@{
      nixpkgs,
      ...
    }:
    let
      inherit (inputs.nixpkgs) lib;
      mylib = import ../lib { inherit lib; };
      myvars = import ../vars { inherit lib; };
    in
    {
      nixosConfigurations = {
        saika = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs // {
            inherit mylib myvars;
          };

          modules = [
            { networking.hostName = "saika"; }

            ./configuration.nix

            ../modules/base
            ../modules/nixos/base/i18n.nix
            ../modules/nixos/base/user-group.nix
            ../modules/nixos/base/ssh.nix

            ../hosts/saika/hardware-configuration.nix
            ../hosts/saika/preservation.nix
          ];
        };

        whitefox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs // {
            inherit mylib myvars;
          };

          modules = [
            { networking.hostName = "whitefox"; }

            ./configuration.nix

            ../modules/base
            ../modules/nixos/base/i18n.nix
            ../modules/nixos/base/user-group.nix
            ../modules/nixos/base/ssh.nix

            ../hosts/whitefox/hardware-configuration.nix
            ../hosts/whitefox/disko.nix
            ../hosts/whitefox/preservation.nix
          ];
        };
      };
    };
}
