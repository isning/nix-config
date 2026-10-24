{
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      mitmproxy # http/https proxy tool

      # IDEs
      # jetbrains.idea-community

    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.wireshark ]
    ++ (lib.optionals (pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64) [
      insomnia # REST client
    ]);
}
