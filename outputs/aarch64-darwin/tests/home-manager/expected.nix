{
  myvars,
  lib,
}:
let
  username = myvars.username;
  hosts = [
    "amiya"
  ];
in
lib.genAttrs hosts (_: "/Users/${username}")
