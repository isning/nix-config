# System Modules

System modules are shared across hosts. Keep hardware-specific settings under `hosts/` and user
settings under `home/`.

| Path                      | Purpose                                                       |
| ------------------------- | ------------------------------------------------------------- |
| `base/`                   | Settings shared by NixOS and nix-darwin                       |
| `darwin/`                 | macOS system configuration                                    |
| `nixos/base/`             | Common Linux services, users, networking, and packages        |
| `nixos/desktop.nix`       | Desktop entry module                                          |
| `nixos/desktop/`          | Audio, Niri, fonts, gaming, peripherals, and desktop services |
| `nixos/server/server.nix` | Server entry module used by Whitefox                          |

Several `default.nix` files use `mylib.scanPaths` to import sibling modules. A file can therefore be
active without an explicit filename reference. Keep helper files in a subdirectory with an explicit
entry module, as the audio module does with `config-packages/`, so they are not imported
accidentally.

Infrastructure generators used by the active hosts remain in `lib/`.

Run `just fmt` and `just test` after shared module changes. Use evaluation or builds before an
explicit deployment; a system switch is not a syntax check.
