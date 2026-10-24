{
  lib,
  kernel,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "snd-soc-skl-hda-dsp-independent-hp";
  version = kernel.modDirVersion;
  src = kernel.src;

  nativeBuildInputs = kernel.moduleBuildDependencies;
  # Module certificates are generated during modules_install; preserve the signed bytes.
  dontStrip = true;

  postUnpack = ''
    moduleRoot="$PWD/module-source"
    mkdir -p "$moduleRoot"
    cp "$sourceRoot/sound/soc/intel/boards/skl_hda_dsp_generic.c" "$moduleRoot/"
    cp ${./independent-hp-module/Makefile} "$moduleRoot/"
    patch --directory="$moduleRoot" --strip=1 \
      < ${./independent-hp-module/skl-hda-dsp-independent-hp.patch}
    sourceRoot="$moduleRoot"
  '';

  buildPhase = ''
    runHook preBuild
    cp ${./independent-hp-module/Makefile} Makefile
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
