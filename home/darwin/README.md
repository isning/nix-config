# Home Manager's Darwin Submodules

This directory contains macOS-specific Home Manager configurations for Darwin systems.

## Configuration Modules

### Core Configurations

- **default.nix**: Entry point that imports all Darwin configurations
- **shell.nix**: Shell configurations and environment settings
- **rime-squirrel.nix**: [Rime Squirrel](https://github.com/rime/squirrel) input method
  configuration
- **linearmouse.nix**: Declarative `~/.config/linearmouse/linearmouse.json`.
  Mice use reversed vertical scrolling at 3 lines per wheel step, with pointer
  acceleration enabled (`0.5`) and speed `0.4` as tuning starting points, not an
  exact Windows acceleration curve. Trackpads are unaffected. Adjust pointer speed
  for the mouse DPI and display on amiya. Edit this module for per-device settings;
  the generated file is read-only, so use Nix instead of GUI edits.

### Application Installation

Ordinary GUI applications use `brew-nix` in `modules/darwin/apps.nix`, using vendor
binaries rather than Homebrew. VS Code and command-line
tools use nixpkgs. Update brew-nix app versions with `nix flake update brew-api`,
then run `just local` on amiya.
Update the packaging code separately with `nix flake update brew-nix` when needed.
Launch the apps once and grant the macOS permissions they request.

Homebrew cleanup is disabled during this trial to preserve existing applications
and preferences. Existing Homebrew copies may still appear in `/Applications`;
use the Nix-managed apps in `/Applications/Nix Apps` when testing. Verify startup,
permissions, and login items on macOS before retiring the old copies. Update these
Nix-managed apps through the flake rather than their built-in updaters.

BetterDisplay and Ice preferences are configured manually in their GUIs; only their
installation is managed by Nix.

WeChat and Tailscale use the Mac App Store through `homebrew.masApps`. Sign in to
the App Store before applying. Tailscale's App Store variant has different service
and CLI capabilities from its standalone variant; use the system SSH client for
Tailscale SSH connections. Approve its VPN configuration after installation.

Homebrew remains for Squirrel (input method registration), Clash Verge Rev
(privileged service), Wireshark (capture permissions), Miniforge (installer and
existing shell integration), and MacFUSE (system driver). These have not been
migrated to simple app bundles because their installation steps must be preserved.

### Window Management

Amiya uses native macOS window management. AeroSpace and JankyBorders are not
installed, and the AeroSpace configuration is not deployed.

### Remote Development Profile

Amiya uses Ghostty with Nushell. Kitty and Alacritty are disabled; Bash and Zsh
remain available for system and shell compatibility. The SSH server is enabled,
with password and keyboard-interactive authentication disabled by the shared
security configuration. Configure an authorized public key before connecting.

Container and Kubernetes tools, their shell aliases, and Kubernetes AI helpers
are disabled on amiya. Codegraph, RTK, and Open Design are also disabled. The
main agent clients remain available. Other hosts retain their existing tools.

The host sets `roles.remote-workstation.enable = true`. Features are selected by
`features.<name>.enable` options, with ordinary host assignments overriding role
defaults. The shared registry loads role and feature definitions once; roles do
not import features. Linux GUI hosts enable `roles.development-workstation`.

### Network Configuration

- **proxy/**: Network proxy configurations
  - `proxychains.conf`: Proxy chains configuration for network routing
  - Proxy settings for development tools and applications

## Features

- macOS-specific package installations and configurations
- Native macOS applications and utilities
- Touch ID and system integration
- Homebrew integration for additional packages
- macOS-specific shell configurations and aliases
