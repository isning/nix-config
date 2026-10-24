{
  lib,
  kernel,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "snd-hda-codec-alc269-independent-hp";
  version = kernel.modDirVersion;
  src = kernel.src;

  nativeBuildInputs = kernel.moduleBuildDependencies;
  # Module certificates are generated during modules_install; preserve the signed bytes.
  dontStrip = true;

  postUnpack = ''
    moduleRoot="$PWD/module-source"
    mkdir -p "$moduleRoot/sound/hda"
    cp -r "$sourceRoot/sound/hda/codecs" "$moduleRoot/sound/hda/codecs"
    cp -r "$sourceRoot/sound/hda/common" "$moduleRoot/sound/hda/common"
    chmod -R u+w "$moduleRoot"

    cp ${./independent-hp-realtek-module/Makefile} \
      "$moduleRoot/sound/hda/codecs/realtek/Makefile"
    patch --directory="$moduleRoot" --strip=1 \
      < ${./independent-hp-realtek-module/alc269-independent-hp.patch}

    sourceRoot="$moduleRoot/sound/hda/codecs/realtek"
  '';

  buildPhase = ''
    runHook preBuild
    make ${lib.escapeShellArgs kernel.commonMakeFlags} \
      -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M="$PWD" modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    make ${lib.escapeShellArgs kernel.commonMakeFlags} \
      -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M="$PWD" \
      INSTALL_MOD_PATH="$out" INSTALL_MOD_DIR=extra DEPMOD=true modules_install
    runHook postInstall
  '';
}
