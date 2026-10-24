{ pkgs, cask }:
cask.overrideAttrs (old: {
  # Match Homebrew's browser user agent requirement without changing the hash.
  src = old.src.overrideAttrs {
    curlOptsList = [
      "--user-agent"
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
    ];
  };

  nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.dmg2img ];

  # Version 3.1.9's GPT partition is shorter than its HFS volume. Reconstruct
  # that volume directly instead of letting 7-Zip truncate it to the GPT size.
  unpackPhase = ''
    runHook preUnpack
    dmg2img -s -p 4 "$src" volume.hfs
    7zz x -tHFS -snld20 volume.hfs
    app=$(find . -mindepth 2 -maxdepth 3 -type d -name '${old.sourceRoot}' -print -quit)
    test -n "$app"
    mv "$app" .
    runHook postUnpack
  '';
})
