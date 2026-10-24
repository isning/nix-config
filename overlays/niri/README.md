# Niri patches

The overlay retains the pinned `losnoco/niri` HDR branch and its matching Smithay input.

## Virtual outputs

`virtual-outputs.patch` ports [upstream PR #3800](https://github.com/niri-wm/niri/pull/3800), commit
`7fd585dd44ed67644977dd9561bb6e8b3837f8f7`, onto Niri commit
`d9131c336ed291ad235a6b46f9af960a45f2bad4`. It adds named virtual outputs, runtime creation/removal,
the `create-virtual` output configuration property, headless input support, and the upstream
virtual-output tests.

The port preserves the HDR branch's renderer dispatch and physical-output redraw scheduling. Virtual
outputs use estimated vblank pacing and virtual-output frame callbacks. Outputs without DRM scanout
report no pending gamma change. This patch does not add HDR support to virtual outputs.

After building and deploying with `just niri`, log out and back in so the running compositor and the
`niri msg` client use the patched version. In that session:

```bash
niri msg create-virtual-output --name sunshine --width 2560 --height 1600 --refresh-rate 120
niri msg outputs
niri msg remove-virtual-output sunshine
```

Do not disable physical outputs until capture of the virtual output has been verified. Sunshine
needs a compatible capture method such as `wlr`; a compositor virtual output is not a DRM/KMS
connector. The overlay only adds compositor support; Saika's Sunshine preparation commands and
automatic physical-display switching are configured separately in
[`hosts/saika/saika/sunshine.nix`](../../hosts/saika/saika/sunshine.nix), with usage documented in
[`SUNSHINE.md`](../../hosts/saika/saika/SUNSHINE.md).

Build only the compositor, without deploying:

```bash
nix build --no-link -L .#nixosConfigurations.saika-niri.pkgs.niri
```

New patch files must be visible to the Git flake source (for example, with `git add -N`).
