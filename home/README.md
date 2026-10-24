# Home Manager's Submodules

This directory contains all Home Manager configurations organized by platform and functionality.

## Workstation Roles

Hosts choose an explicit role alongside their platform module:

```nix
imports = [
  ../../darwin
  ../../roles/remote-workstation.nix
];
```

- `roles/remote-workstation.nix`: Shared workstation configuration, Ghostty,
  Nushell, SSH/Git, and main AI clients. Used by amiya. It preserves the existing
  editor, cloud, security, and desktop tools; the role does not automatically
  install container/Kubernetes tools or AI utilities.
- `roles/development-workstation.nix`: Extends the remote workstation with
  container/Kubernetes tools, Codegraph/RTK/Open Design, and additional terminals.
  Used by the Linux GUI entry point, including saika.

Role imports are explicit. Feature modules under `features/` own package and
configuration selection:

- `agents.nix`: Codex, Claude Code, Gemini CLI, and OpenCode.
- `agent-utilities.nix`: Codegraph, RTK, and Open Design.
- `containers.nix`: Container image and Compose tools.
- `kubernetes.nix`: Kubernetes clients, TUI, aliases, and shell integration.
- `kubernetes-ai.nix`: Kubernetes AI helpers.
- `terminal.nix`: Ghostty and shared interactive shell configuration.
- `development-tools.nix`: Development, cloud, and language tooling.
- `security.nix`: Hardware-key, encryption, GPG, and password-store tools.
- `desktop-tools.nix`: Shared desktop development and media tools.

Add optional feature modules to a role rather than importing everything and
disabling modules per host. Platform modules provide operating-system settings.
The legacy `linux/tui.nix` entry point retains its existing selection.
Removed feature paths have no compatibility forwarding modules; callers import
the feature modules directly.

System-level roles are separate from Home Manager. Amiya imports
`../modules/roles/darwin-remote-workstation.nix` from its system host module; it
selects the macOS app installation module and enables the SSH server. Do not
import system modules into Home Manager roles.

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
