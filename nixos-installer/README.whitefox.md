# Whitefox Bootstrap

Use the [bootstrap flake](README.md) to prepare Whitefox before deploying the main server
configuration. Review the actual
[hardware configuration](../hosts/whitefox/hardware-configuration.nix) and
[disk layout](../hosts/whitefox/disko-fs.nix), including the disk ID, before preparing filesystems.
The bootstrap output is `whitefox`; the main output and hostname are also `whitefox`.

## Validate and install

From `nixos-installer/`:

```bash
just test whitefox
```

After the intended filesystems are mounted under `/mnt`:

```bash
nixos-install --root /mnt --flake .#whitefox
```

## Persistent state

The root filesystem is ephemeral. Review [preservation.nix](../hosts/whitefox/preservation.nix) and
ensure essential state, including machine identity, SSH host keys, and the user's home, is stored
under `/persistent` before the first reboot. Preserve existing machine identity when migrating an
installation.

## Main configuration

Follow [secrets/README.md](../secrets/README.md) to rekey agenix secrets for Whitefox's host key.
Review [Secure Boot settings](../hosts/whitefox/secureboot.nix) before enabling that boot path.

From the repository root on Whitefox, apply its main configuration with:

```bash
just local
```

For an explicit remote deployment from a management machine, use `just col whitefox`.
