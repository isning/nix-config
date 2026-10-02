# nix-config

NixOS, nix-darwin, and Home Manager configuration for the active hosts below.

| Flake output | Platform            | Hostname   | Role                                     |
| ------------ | ------------------- | ---------- | ---------------------------------------- |
| `saika-niri` | x86_64 Linux        | `saika`    | Niri desktop with Home Manager           |
| `whitefox`   | x86_64 Linux        | `whitefox` | Homelab server, deployed through Colmena |
| `amiya`      | Apple Silicon macOS | `amiya`    | nix-darwin with Home Manager             |

## Working on the configuration

```bash
just fmt
just test
nix flake check --no-build
```

On Saika, apply the desktop configuration with `just niri`. Remote deployments are explicit; see
`just --list` for the available commands.

## Layout

- [outputs/](outputs/README.md): host registration and evaluation tests.
- [hosts/](hosts/README.md): hardware and host-specific configuration.
- [home/](home/README.md): shared and per-host Home Manager modules.
- [modules/](modules/README.md): shared system modules.
- [nixos-installer/](nixos-installer/README.md): separate bootstrap flake for Saika and Whitefox.

Secrets are managed with agenix and a private input; see [secrets/](secrets/README.md).
