# Home Manager's Darwin Submodules

This directory contains macOS-specific Home Manager configurations for Darwin systems.

## Configuration Modules

### Core Configurations

- **default.nix**: Entry point that imports all Darwin configurations
- **shell.nix**: Shell configurations and environment settings
- **linearmouse.nix**: Declarative `~/.config/linearmouse/linearmouse.json`. Mice use reversed
  vertical scrolling at 3 lines per wheel step, with pointer acceleration enabled (`0.5`) and speed
  `0.4` as tuning starting points, not an exact Windows acceleration curve. Trackpads are
  unaffected. Adjust pointer speed for the mouse DPI and display on amiya. Edit this module for
  per-device settings; the generated file is read-only, so use Nix instead of GUI edits.

### Application Installation

Ordinary GUI applications use `brew-nix` in `modules/darwin/apps.nix`, using vendor binaries without
installing Homebrew. VS Code and command-line tools use nixpkgs. Update brew-nix app versions with
`nix flake update brew-api`, then run `just local` on amiya. Update the packaging code separately
with `nix flake update brew-nix` when needed. Launch the apps once and grant the macOS permissions
they request.

Homebrew is disabled. Existing manually installed copies may still appear in `/Applications`; use
the Nix-managed apps in `/Applications/Nix Apps` when testing. Verify startup, permissions, and
login items on macOS before retiring the old copies. Update these Nix-managed apps through the flake
rather than their built-in updaters.

BetterDisplay and Ice preferences are configured manually in their GUIs; only their installation is
managed by Nix.

WeCom, WeChat, Feishu, and Tencent Meeting use brew-nix and update through `brew-api` along with the
other desktop applications. Grant microphone, camera, and screen recording permissions in macOS when
requested.

Install Tailscale manually from the Mac App Store. Its App Store variant has different service and
CLI capabilities from its standalone variant; use the system SSH client for Tailscale SSH
connections. Approve its VPN configuration after installation.

FlClash replaces Clash Verge Rev on macOS. Its small Nix package reads the version and checksums
from the author's tap, pinned by the `flclash-tap` input. `just up` updates it along with the other
inputs; use `just upp flclash-tap` to update only FlClash, then `just local` on amiya. No Homebrew
or Ruby is needed.

For TUN support, nix-darwin copies FlClash's signed bundle to a root-owned versioned directory under
`/Library/Application Support/nix-config/flclash` and links it at `/Applications/FlClash.app`. Only
its bundled Core receives the upstream-required `root:admin` ownership and mode `4750`. An
administrator account is required. An existing unmanaged `/Applications/FlClash.app` must be moved
aside before deploying. Previous versioned copies remain available for rollback. Update through Nix;
the installed bundle is not writable by the application's updater. Disable the old proxy client
before enabling FlClash, and import the subscription in FlClash's GUI.

Wireshark also uses brew-nix. A nix-darwin launch daemon pre-creates BPF devices at boot and grants
the configured user capture access; Homebrew and the separate ChmodBPF installer are unnecessary.
Application launch, TUN, and live capture still need validation on macOS.

NetEase Music uses a local Nix package override in `modules/darwin/packages/neteasemusic.nix`: it
sets the required browser user agent and reconstructs the vendor DMG's HFS volume before extraction.
The vendor checksum and strict extraction checks remain enabled. Squirrel, Miniforge, and MacFUSE
are no longer declared, and Conda shell initialization is removed. Previously installed applications
are not automatically removed.

### Window Management

Amiya uses native macOS window management. AeroSpace and JankyBorders are not installed, and the
AeroSpace configuration is not deployed.

All four hot corners are disabled. Clicking the wallpaper reveals the desktop, and macOS switches
between light and dark appearance automatically. Input methods are managed through macOS System
Settings; this configuration neither installs Squirrel nor manages `~/Library/Rime`.

### Remote Development Profile

Amiya uses Ghostty with Nushell. Kitty and Alacritty are disabled; Bash and Zsh remain available for
system and shell compatibility. The SSH server is enabled, with password and keyboard-interactive
authentication disabled by the shared security configuration. Configure an authorized public key
before connecting.

Local language toolchains, language servers, AI agents, Terraform, and local development utilities
are disabled on amiya. Container/Kubernetes tools, Codegraph, RTK, and Open Design also stay
disabled. The credentials group, including the template's Pass configuration, and CLI
media-processing tools are disabled. Other hosts retain their existing tools.

Moonlight, Tailscale, VS Code, JetBrains Toolbox, OBS, Wireshark, SSH, and the shared terminal tools
remain available for remote use. Toolbox is controlled by `features.ide-clients.enable`, separately
from language toolchains and local development utilities. Existing everyday desktop applications are
retained; Insomnia and the separate Clash CLI are removed.

OBS is managed in the shared `home/base/gui/media.nix` through `features.media.recording.enable`.
macOS uses the vendor application bundle; Linux retains its OBS plugin wrapper and plugins. This
option is independent of CLI media-processing tools.

The host sets `roles.remote-workstation.enable = true`. Features are selected by
`features.<name>.enable` options, with ordinary host assignments overriding role defaults. The
shared registry loads role and feature definitions once; roles do not import features. Linux GUI
hosts enable `roles.development-workstation`.

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
