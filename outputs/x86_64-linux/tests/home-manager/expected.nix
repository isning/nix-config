{
  myvars,
  lib,
}:
let
  username = myvars.username;
  hosts = [
    "saika-niri"
  ];
in
lib.genAttrs hosts (_: "/home/${username}")
