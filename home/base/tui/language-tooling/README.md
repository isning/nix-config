# Language Tooling

This directory contains local language runtimes, compilers, build tools, language servers,
formatters, and document tooling. [`packages.nix`](./packages.nix) declares the packages;
[`default.nix`](./default.nix) applies them when `features.language-tooling.enable` is enabled.

Editor programs, keymaps, `$EDITOR` defaults, and usage docs live under
[`../../core/editors/`](../../core/editors/README.md) (Helix, Neovim backup, glossary, cheatsheets).

IDE clients such as JetBrains Toolbox use `features.ide-clients.enable` separately. A remote
workstation can enable its clients without installing a local language environment. Development
workstations enable language tooling by default.
