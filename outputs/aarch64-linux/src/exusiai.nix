{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.nixosSystem`, `mylib.colmenaSystem`, etc.
  inputs,
  lib,
  mylib,
  myvars,
  system,
  genSpecialArgs,
  ...
}@args:
let
  name = "exusiai";
  tags = [
    name
  ];
  ssh-user = "root";

  modules = {
    nixos-modules =
      (map mylib.relativeToRoot [
        # common
        "secrets/nixos.nix"
        "modules/nixos/server/server-aarch64.nix"
        # host specific
        "hosts/${name}"
      ])
      ++ [
        {
          modules.secrets.server.application.enable = true;
          modules.secrets.preservation.enable = true;
        }
      ]
      ++ [
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
      ];
  };

  systemArgs = modules // args;
in
{
  nixosConfigurations.${name} = mylib.nixosSystem systemArgs;

  colmena.${name} = mylib.colmenaSystem (systemArgs // { inherit tags ssh-user; });

  packages.${name} = inputs.self.nixosConfigurations.${name}.config.formats.sd-aarch64;
}
