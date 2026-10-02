{
  myvars,
  lib,
  outputs,
}:
let
  username = myvars.username;
  hosts = builtins.filter (
    name: outputs.darwinConfigurations.${name}.config ? home-manager.users.${username}
  ) (builtins.attrNames outputs.darwinConfigurations);
in
lib.genAttrs hosts (
  name: outputs.darwinConfigurations.${name}.config.home-manager.users.${username}.home.homeDirectory
)
