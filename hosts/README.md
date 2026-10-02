# Hosts

| Directory       | Flake output | Platform             |
| --------------- | ------------ | -------------------- |
| `saika/`        | `saika-niri` | x86_64 Linux desktop |
| `whitefox/`     | `whitefox`   | x86_64 Linux server  |
| `darwin-amiya/` | `amiya`      | Apple Silicon macOS  |

Hardware and host-specific settings belong here. Shared system settings belong in `modules/`; shared
user settings belong in `home/`.

## Adding a host

1. Create `hosts/<name>/default.nix` and its hardware configuration where applicable.
2. If the host uses Home Manager, add one entry module under `home/hosts/<platform>/`.
3. Register the host in `outputs/<system>/src/<name>.nix`, using a similar active host as a
   template.
4. Update hostname and Home Manager test expectations under `outputs/<system>/tests/`.
5. Add any required networking variables and agenix configuration without committing secret values.
6. Run `just fmt` and `just test` before deploying.

A desktop variant may use an output such as `saika-niri` while retaining hostname `saika`.
