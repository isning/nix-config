{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.desktop-tools.enable {

    home.packages =
      with pkgs;
      [
        mitmproxy # http/https proxy tool
        wireshark # network analyzer

        # IDEs
        # jetbrains.idea-community

      ]
      ++ (lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
        insomnia # REST client
      ]);
  };
}
