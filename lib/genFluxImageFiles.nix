{
  pkgs,
  fluxSource,
  fluxPath ? ".",
  namespaces ? [ ],
  imageArch ? null,
  compressAsZstd ? false,
  zstdLevel ? 10,
  # Filtering options (all optional, defaults allow all):
  # - namespaces: list of namespaces to include (empty = all, from sources/targets)
  # - imageArch: image architecture to match (null = all)
  # - customFilter: optional custom predicate function (entry -> bool)
  #   If provided, it is combined with base namespace/arch matching.
  #   Example: entry: builtins.any (t: t.kind == "Deployment") (entry.targets or [ ])
  customFilter ? null,
  ...
}:
let
  lib = pkgs.lib;
  lockFile = "${toString fluxSource}/${fluxPath}/images.lock.nix";
  lockEntries = if builtins.pathExists lockFile then import lockFile else [ ];

  # Define individual matchers
  entryNamespaces =
    entry:
    let
      targetNamespaces = map (t: t.namespace or "") (entry.targets or [ ]);
      sourceNamespaces = map (s: s.namespace or "") (entry.sources or [ ]);
      chainNamespaces = builtins.concatLists (
        map (chain: map (s: s.namespace or "") chain) (entry.sourceChains or [ ])
      );
    in
    builtins.filter (x: x != "") (lib.unique (targetNamespaces ++ sourceNamespaces ++ chainNamespaces));

  namespaceMatch =
    entry: namespaces == [ ] || builtins.any (ns: builtins.elem ns (entryNamespaces entry)) namespaces;

  archMatch = entry: imageArch == null || !entry ? arch || entry.arch == imageArch;

  # Combine base matchers with optional customFilter
  entryMatch =
    entry:
    namespaceMatch entry
    && archMatch entry
    && (if customFilter != null then customFilter entry else true);

  hasPullImageFields =
    entry:
    let
      imageName = entry.imageName or (entry.finalImageName or null);
    in
    imageName != null && (entry ? imageDigest) && (entry ? hash);

  toPullImage =
    entry:
    let
      imageName = entry.imageName or (entry.finalImageName or null);
      finalImageName = entry.finalImageName or imageName;
      finalImageTag = entry.finalImageTag or "latest";
      os = entry.os or "linux";
      arch = entry.arch or (if imageArch == null then "amd64" else imageArch);
    in
    pkgs.dockerTools.pullImage {
      inherit
        imageName
        finalImageName
        finalImageTag
        os
        arch
        ;
      imageDigest = entry.imageDigest;
      hash = entry.hash;
    };

  selectedEntries = builtins.filter entryMatch lockEntries;
  validEntries = builtins.filter hasPullImageFields selectedEntries;
  skippedEntries = builtins.length selectedEntries - builtins.length validEntries;
  pulledImages = map toPullImage validEntries;

  toZstdImage =
    image:
    let
      base = builtins.baseNameOf (toString image);
    in
    pkgs.runCommand "${base}.zst" { nativeBuildInputs = [ pkgs.zstd ]; } ''
      zstd -q -T0 -${toString zstdLevel} --stdout ${image} > "$out"
    '';

  # Keep this visible during evaluation without forcing module wiring.
  _ =
    if skippedEntries > 0 then
      builtins.trace "genFluxImageFiles skipped ${toString skippedEntries} lock entries missing fields required by dockerTools.pullImage (imageName/finalImageName, imageDigest, hash)." null
    else
      null;
in
if compressAsZstd then map toZstdImage pulledImages else pulledImages
