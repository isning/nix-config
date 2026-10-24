# Home Manager's Submodules

This directory contains all Home Manager configurations organized by platform and functionality.

## Workstation Roles and Feature Options

Role and feature definitions are registered once in `home/default.nix`. Platform
entry points keep explicit imports of `base/core`, `base/tui`, `base/gui` (GUI
hosts), and `base/home.nix`. Hosts select roles through
options; roles set feature defaults without importing feature modules.

```nix
# amiya
roles.remote-workstation.enable = true;

# Linux GUI workstation
roles.development-workstation.enable = true;

# Optional host overrides
features.agents.enable = false;
features.kubernetes.enable = true;
```

- `roles.remote-workstation.enable`: Ghostty, main agent clients, development,
  credential, and desktop tools. Used by amiya.
- `roles.development-workstation.enable`: Remote-workstation defaults plus
  container/Kubernetes tools, AI utilities, and additional terminals. Used by
  Linux GUI hosts including saika.

Feature options default to disabled. Role selections use `mkDefault`, so a host
can override a feature with an ordinary assignment. Packages, aliases, and
settings are conditional on the same option with `mkIf`.

Available `features.<name>.enable` options:

- `agents`, `agent-utilities`
- `containers`, `kubernetes`, `kubernetes-ai`
- `terminal`, `additional-terminals`
- `development-tools`, `credentials`, `desktop-tools`

The Linux terminal-only entry point selects features directly. Shared SSH client
and basic shell configuration remain in the base layer. Darwin/Linux platform
modules load the registry once; no compatibility forwarding modules are used.

System-level and Home Manager options are separate. Amiya selects
`roles.remote-workstation.enable` in both configurations. The Darwin system role
sets `features.desktop-apps.enable` and enables the SSH server. The app module is
registered once in the Darwin registry and applies its configuration with `mkIf`.

## Current Structure

```
home/
├── base/              # Cross-platform home manager configurations
│   ├── core/          # Essential applications and settings
│   │   ├── editors/   # Editor configurations (Neovim, Helix)
│   │   ├── shells/    # Shell configurations (Nushell, Zellij)
│   │   └── ...
│   ├── gui/           # GUI applications and desktop settings
│   │   ├── terminal/  # Terminal emulators (Kitty, Alacritty, etc.)
│   │   └── ...
│   ├── tui/           # Terminal/TUI applications
│   │   ├── editors/   # Heavy editor/tooling pkgs only (`packages.nix`; core editors live under `core/editors`)
│   │   ├── encryption/ # GPG, password-store, etc.
│   │   └── ...
│   └── home.nix       # Main home manager entry point
├── linux/             # Linux-specific home manager configurations
│   ├── base/          # Linux base configurations
│   ├── gui/           # Linux GUI applications
│   │   ├── niri/      # Niri window manager
│   │   └── ...
│   ├── editors/       # Linux-specific editors
│   └── ...
├── hosts/             # Host-specific home manager entry modules
│   ├── linux/         # Linux host home modules (saika)
│   └── darwin/        # macOS host home modules (darwin-amiya)
└── darwin/            # macOS-specific home manager configurations
    ├── aerospace/     # macOS window manager
    ├── proxy/         # Proxy configurations
    └── ...
```

## Module Overview

1. **base**: The base module suitable for both Linux and macOS
   - Cross-platform applications and settings
   - Shared configurations for editors, shells, and essential tools

2. **linux**: Linux-specific configuration
   - Desktop environments (Noctalia Shell, Niri compositor)
   - Linux-specific GUI applications
   - System integration tools

3. **darwin**: macOS-specific configuration
   - macOS applications and services
   - Platform-specific integrations (Aerospace, Squirrel, etc.)

4. **hosts**: Host entry modules for Home Manager
   - Each output should reference only one host home module file
   - Host modules are responsible for importing shared stacks (`home/linux/*` or `home/darwin`) and
     applying host overrides
