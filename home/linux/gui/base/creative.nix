{
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      # creative
      # gimp      # image editing, I prefer using figma in browser instead of this one
      inkscape # vector graphics
      krita # digital painting
      # musescore # music notation
      # reaper # audio production
      # sonic-pi # music programming

      # 2d game design
      # aseprite # Animated sprite editor & pixel art tool

      # this app consumes a lot of storage, so do not install it currently
      # kicad     # 3d printing, electrical engineering

      # office
      libreoffice-qt-stable
      hunspell # spell check for libreoffice
      hunspellDicts.en_US # USA English
      hyphenDicts.en_GB # British English

    ]
    ++ (lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      # ldtk # A modern, versatile 2D level editor

      # fpga
      # python313Packages.apycula # gowin fpga
      # yosys # fpga synthesis
      # nextpnr # fpga place and route
      # openfpgaloader # fpga programming
      # nur-ryan4yin.packages.${pkgs.stdenv.hostPlatform.system}.gowin-eda-edu-ide # app: `gowin-env` => `gw_ide` / `gw_pack` / ...
    ]);
}
