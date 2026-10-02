# Bootstrap Flake

This separate flake prepares a minimal NixOS installation for `saika` or `whitefox`. It imports
hardware and preservation settings from the main repository; it does not install the full desktop or
server configuration.

Review the target host's hardware and disk configuration before installing:

- Saika: [hardware](../hosts/saika/hardware-configuration.nix),
  [disk layout](../hosts/saika/disko-fs.nix), [preservation](../hosts/saika/preservation.nix).
- Whitefox: [hardware](../hosts/whitefox/hardware-configuration.nix),
  [disk layout](../hosts/whitefox/disko-fs.nix), [preservation](../hosts/whitefox/preservation.nix),
  [installation notes](README.whitefox.md).

## Validate

From this directory:

```bash
just test          # Build the Saika bootstrap system
just test whitefox # Build the Whitefox bootstrap system
```

These commands build without switching the running system. The bootstrap flake has its own lock
file, separate from the main repository.

## Install

After preparing and mounting the intended target filesystems under `/mnt`, install the appropriate
bootstrap output:

```bash
nixos-install --root /mnt --flake .#saika
# Or, on the Whitefox target:
nixos-install --root /mnt --flake .#whitefox
```

Rekey agenix secrets for the target host using [secrets/README.md](../secrets/README.md) before
applying the main configuration. After booting Saika, run `just niri` from the repository root. For
Whitefox, use the explicit Colmena deployment workflow documented by `just --list`.
