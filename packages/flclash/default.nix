{ pkgs }:
let
  version = "0.9.5-pre.1";
  arm = pkgs.stdenv.hostPlatform.isAarch64;
  arch = if arm then "arm64" else "amd64";
  src = pkgs.fetchurl {
    url = "https://github.com/chen08209/FlClash/releases/download/v${version}/FlClash-${version}-linux-${arch}.AppImage";
    sha256 =
      if arm then
        "24de3aac52816c6a15ffca8308ae804e0bdbedd7658541ea9a206e148395b61a"
      else
        "e87685f91ff9940fc0665ce0b8d1ffad8638fe474d0df121df1b078db256ed0a";
  };
  contents = pkgs.appimageTools.extract {
    pname = "flclash";
    inherit version src;
  };
  helper = pkgs.stdenvNoCC.mkDerivation {
    pname = "flclash-helper";
    inherit version;
    dontUnpack = true;
    dontStrip = true;
    dontAutoPatchelf = true;
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];
    installPhase = ''
      mkdir -p "$out/bin"
      cp ${contents}/FlClashHelperService ${contents}/FlClashCore "$out/bin/"
      chmod u+w "$out/bin/FlClashHelperService"
      autoPatchelf "$out/bin/FlClashHelperService"
    '';
  };
  bundle =
    pkgs.runCommand "flclash-${version}-bundle"
      {
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        buildInputs = with pkgs; [
          gtk3
          libepoxy
          libglvnd
          libx11
          stdenv.cc.cc.lib
        ];
        dontAutoPatchelf = true;
      }
      ''
        mkdir -p "$out"
        cp -r ${contents}/. "$out/"
        chmod u+w "$out" "$out/FlClash" "$out/lib" "$out/lib/"*.so
        unlink "$out/FlClashHelperService"
        cp ${helper}/bin/FlClashHelperService "$out/FlClashHelperService"
        addAutoPatchelfSearchPath "$out/usr/lib"
        autoPatchelf "$out/FlClash" "$out/lib"
      '';
  appId = "com.follow.clash";
  desktop = pkgs.makeDesktopItem {
    name = appId;
    desktopName = "FlClash";
    exec = "flclash %u";
    icon = appId;
    startupNotify = true;
    startupWMClass = appId;
    mimeTypes = [
      "x-scheme-handler/clash"
      "x-scheme-handler/clashmeta"
      "x-scheme-handler/flclash"
    ];
    categories = [ "Network" ];
  };
in
pkgs.runCommand "flclash-${version}"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    passthru = { inherit bundle; };
    meta = {
      mainProgram = "flclash";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
  }
  ''
    makeWrapper "${bundle}/FlClash" "$out/bin/flclash" \
      --unset APPIMAGE \
      --prefix LD_LIBRARY_PATH : "${bundle}/lib:${bundle}/usr/lib:${pkgs.libglvnd}/lib"
    install -Dm644 ${desktop}/share/applications/${appId}.desktop \
      "$out/share/applications/${appId}.desktop"
    for size in 128x128 256x256; do
      icon="$out/share/icons/hicolor/$size/apps"
      mkdir -p "$icon"
      ${pkgs.buildPackages.imagemagick}/bin/magick ${contents}/FlClash.png \
        -resize "$size" "$icon/${appId}.png"
    done
  ''
