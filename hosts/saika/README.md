# Host - Saika

Desktop (NixOS + preservation, LUKS + btrfs on nvme). Disk layout is declarative via
[disko](./disko-fs.nix) (see the disk ID in that file).

Related:

- [nixos-installer README](/nixos-installer/README.md) – install from ISO using disko
- [disko-fs.nix](./disko-fs.nix) – partition/layout definition (ESP + LUKS + btrfs)

## TODOs

1. Install DCGM-Exporter on `saika` to monitor the GPU status.

## Codex official Remote Control

`codex-remote-control.service` runs the `llm-agents.nix` Codex app-server directly under the user
systemd manager, starts at boot, and survives logout. Official Remote Control is enabled;
credentials and state stay in the preserved `~/.codex`. The service uses a local Unix socket for
pairing and opens no TCP listener.

The CLI wrapper disables `daemon_auto_start`, following nixpkgs#567051. Ordinary CLI sessions run
in-process. The service does not bootstrap a separate daemon package or start an updater; its
version changes only through Nix deployments. Avoid `codex remote-control start` and
`codex app-server daemon bootstrap`, which use the upstream managed-install path instead of this
service.

Apply with `just niri`. Sign in with `codex login` if needed, then check and pair:

```bash
systemctl --user restart codex-remote-control.service
systemctl --user status codex-remote-control.service
codex remote-control pair
```

Enter the short-lived pairing code in the official client. Pairing codes are secrets; keep them out
of repository files and shared logs. Availability depends on the account and workspace's Remote
Control policy. Use `systemctl --user stop codex-remote-control.service` to stop access.

The internal app-server flags `--remote-control` and `--managed-daemon` were checked against Codex
0.159.2. The latter saves loaded threads on graceful shutdown; it does not install a daemon. Recheck
these flags when upgrading. See the official
[developer commands documentation](https://learn.chatgpt.com/docs/developer-commands#codex-remote-control).

## T3 Code LAN service

T3 Code runs as the user's `t3code.service` on `0.0.0.0:3773`, starts at boot, and survives logout
through lingering. The desktop package is not installed. State, worktrees, and authentication
secrets are preserved in `~/.t3` with mode `0700`; the service creates files with umask `0077` and
disables core dumps. Provider CLIs are available through the user profile.

Apply with `just niri`, then check:

```bash
systemctl --user status t3code.service
journalctl --user -u t3code.service -n 50
```

The service uses `start --mode desktop --no-browser` to avoid printing startup pairing secrets into
the journal. A non-loopback listener still requires T3's one-time pairing authentication. Generate a
five-minute link locally, replacing `<lan-ip>` with this host's reachable LAN address, and open it
on the client:

```bash
t3 auth pairing create --ttl 5m --base-url http://<lan-ip>:3773
```

Each device needs its own link. Links are secrets; do not share them in logs. Inspect or revoke a
paired device's session with:

```bash
t3 auth session list
t3 auth session revoke <session-id>
```

LAN access uses HTTP, so authentication does not encrypt traffic. Use this only on a trusted LAN and
do not forward port 3773 to the internet. For encrypted remote access, use Tailscale or an HTTPS
reverse proxy. See the upstream
[remote access documentation](https://github.com/pingdotgg/t3code/blob/v0.0.44/docs/user/remote-access.md).

## Measured Boot Recovery

If Lanzaboote installation fails with `Failed to submit AuthorizeNV policy: Remote address changed`,
the local `/var/lib/systemd/pcrlock.json` can be stale or incompatible with the TPM NV policy. The
error is misleading; `systemd-pcrlock` may also be absent from `PATH` even though it is in the
active system profile.

Keep a working manual LUKS passphrase before changing the TPM enrollment. On `saika`, the recovery
sequence was:

```bash
# 1. Confirm that the manual recovery path works.
sudo cryptsetup open --test-passphrase /dev/disk/by-partlabel/disk-s790-4t-root

# 2. Back up the current policy.
sudo cp -a /var/lib/systemd/pcrlock.json /var/lib/systemd/pcrlock.json.bak

# 3. Remove the stale policy from the TPM NV index.
sudo /run/current-system/systemd/lib/systemd/systemd-pcrlock remove-policy

# 4. Recreate /var/lib/systemd/pcrlock.json from the current measurements.
sudo systemctl restart systemd-pcrlock-make-policy.service

# 5. Wipe only the old TPM2 LUKS slot and enroll it against the new pcrlock policy.
sudo /run/current-system/systemd/bin/systemd-cryptenroll \
  --wipe-slot=tpm2 \
  --tpm2-device=auto \
  --tpm2-pcrlock=/var/lib/systemd/pcrlock.json \
  /dev/disk/by-partlabel/disk-s790-4t-root

# 6. Verify the policy service and LUKS2 token metadata.
sudo systemctl --no-pager --full status systemd-pcrlock-make-policy.service
sudo cryptsetup luksDump /dev/disk/by-partlabel/disk-s790-4t-root
```

Do not use `tpm2_clear`: it clears the whole TPM and is unnecessary for this recovery. Keep the
manual passphrase available until a reboot has confirmed TPM2 unlocking.

## Rust build cache

Rust intermediates and the shared compiler cache live on the dedicated Btrfs subvolume
`@rust-cache`, mounted at `/var/cache/rust`. Each user has a private directory; each workspace or
worktree gets its own Cargo path-hash directory:

```text
/var/cache/rust/<user>/build/<workspace-path-hash>/
/var/cache/rust/<user>/kache/
```

`CARGO_BUILD_BUILD_DIR` sets Cargo's intermediate directory, including dependency artifacts and
incremental compilation state. Final binaries and documentation remain in each project's normal
`target/`. Kache reuses eligible compiler outputs across the isolated build directories, and keeps
adaptive incremental compilation enabled for crates being edited.

The subvolume is a sibling of `@persistent`, so the existing btrbk snapshot policy does not retain
build-cache blocks. Disko declares its mount with compression and `relatime`; standard
systemd-tmpfiles rules create the private user directories and set their permissions.

Overstay's Cargo shim records both the final target and the independent build directory. The local
package patch uses offline Cargo metadata to expand path templates and enrolls build directories
only under the configured cache root. It also trims Kache's `incremental.kache-auto/v1` payloads
while keeping their lock files and metadata, and respecting both Cargo and Kache locks.

The initial budgets are 75 GiB across Overstay's tracked directories, 20 GiB per directory, and 50
GiB for Kache. These are soft budgets: active builds and shared reflink blocks can temporarily keep
usage above them. Overstay owns directory eviction; Kache's overlapping automatic directory cleaners
are disabled. Its own compiler-cache GC remains enabled. Overstay's registry persists separately
under `~/.local/share/cargo-overstay`, so resetting the cache subvolume does not erase it.

For an existing installation, create the subvolume once if it does not already exist before
switching. New installations create it through disko.

```bash
sudo btrfs subvolume create /btr_pool/@rust-cache
sudo chmod 0755 /btr_pool/@rust-cache
just niri
```

Then open a new login session and check:

```bash
findmnt /var/cache/rust
just rust-cache-doctor
just rust-cache-status
systemctl --user status kache.service
```

Check `command -v cargo` inside IDE terminals and dev shells too: it should resolve to
`~/.cargo-overstay/bin/cargo`. A dev shell that prepends another Cargo can bypass the shim;
`cargo overstay exec -- build` is an explicit tracking entry point. Existing project artifacts are
not migrated or scanned across the home directory; new builds use the centralized directory and
register their paths.

`just test-rust-cache` exercises real isolated Cargo builds, worktree separation, cache reuse,
adaptive incremental state, stale-directory GC, and Cargo locks.

Before manually resetting the subvolume, stop its Kache user service and finish all builds and
tests. Keep the mount, user directory permissions, and the `build/` and `kache/` directories intact
before building again. A subvolume is an isolation boundary, not a hard quota or automatic
disk-space reservation.

## Info

Current disk status and mountpoints (example; after migration layout is on nvme1n1):

```bash
› df -Th
Filesystem                Type      Size  Used Avail Use% Mounted on
devtmpfs                  devtmpfs  1.6G     0  1.6G   0% /dev
tmpfs                     tmpfs      16G  8.0K   16G   1% /dev/shm
tmpfs                     tmpfs     7.8G  7.9M  7.8G   1% /run
tmpfs                     tmpfs      16G  1.1M   16G   1% /run/wrappers
tmpfs                     tmpfs      16G   87M   16G   1% /
/dev/mapper/crypted-nixos btrfs     1.9T  630G  1.3T  34% /persistent
/dev/mapper/crypted-nixos btrfs     1.9T  630G  1.3T  34% /nix
tmpfs                     tmpfs     4.0M     0  4.0M   0% /sys/fs/cgroup
efivarfs                  efivarfs  256K  108K  144K  43% /sys/firmware/efi/efivars
/dev/mapper/crypted-nixos btrfs     1.9T  630G  1.3T  34% /snapshots
/dev/mapper/crypted-nixos btrfs     1.9T  630G  1.3T  34% /swap
/dev/nvme0n1p1            vfat      597M  108M  490M  19% /boot
tmpfs                     tmpfs     3.2G   48K  3.2G   1% /run/user/1000
//192.168.5.194/Downloads cifs      3.7T  3.0T  699G  82% /home/ryan/SMB-Downloads
tmpfs                     tmpfs     100K     0  100K   0% /var/lib/lxd/shmounts
tmpfs                     tmpfs     100K     0  100K   0% /var/lib/lxd/devlxd
/dev/mapper/crypted-nixos btrfs     1.9T  630G  1.3T  34% /tmp

~
› lsblk
NAME              MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
nvme0n1           259:0    0  1.8T  0 disk
├─nvme0n1p1       259:1    0  598M  0 part  /boot
└─nvme0n1p2       259:2    0  1.8T  0 part
  └─crypted-nixos 254:0    0  1.8T  0 crypt /swap/swapfile
                                            /gnu/store
                                            /swap
                                            /tmp
                                            /snapshots
                                            /gnu
                                            /btr_pool
                                            /var/log
                                            /var/lib/qemu
                                            /var/lib/tailscale
                                            /var/lib/systemd
                                            /var/lib/private
                                            /var/lib/nixos
                                            /var/lib/lxd
                                            /var/lib/lxc
                                            /var/lib/libvirt
                                            /var/lib/iwd
                                            /var/lib/flatpak
                                            /var/lib/containers
                                            /var/lib/cni
                                            /var/lib/NetworkManager
                                            /var/lib/bluetooth
                                            /home/ryan/work
                                            /home/ryan/nix-config
                                            /home/ryan/tmp
                                            /home/ryan/go
                                            /home/ryan/codes
                                            /home/ryan/Videos
                                            /home/ryan/Pictures
                                            /home/ryan/Music
                                            /home/ryan/Games
                                            /home/ryan/Downloads
                                            /home/ryan/.zoom
                                            /home/ryan/Documents
                                            /home/ryan/.wakatime
                                            /home/ryan/.vscode
                                            /home/ryan/.var
                                            /home/ryan/.terraform.d/plugin-cache
                                            /home/ryan/.steam
                                            /home/ryan/.ssh
                                            /home/ryan/.pulumi
                                            /home/ryan/.pki
                                            /home/ryan/.npm
                                            /home/ryan/.mozilla
                                            /home/ryan/.m2
                                            /home/ryan/.local/state/wireplumber
                                            /home/ryan/.local/state/nvim
                                            /home/ryan/.local/state/home-manager
                                            /home/ryan/.local/share/uv
                                            /home/ryan/.local/state/Heroic
                                            /home/ryan/.local/state/nix/profiles
                                            /home/ryan/.local/share/zoxide
                                            /home/ryan/.local/share/umu
                                            /home/ryan/.local/share/tiled
                                            /home/ryan/.local/share/steel
                                            /home/ryan/.local/share/remmina
                                            /home/ryan/.local/share/password-store
                                            /home/ryan/.local/share/opencode
                                            /home/ryan/.local/share/nvim
                                            /home/ryan/.local/share/nix
                                            /home/ryan/.local/share/krita
                                            /home/ryan/.local/share/lutris
                                            /home/ryan/.local/share/keyrings
                                            /home/ryan/.local/share/k9s
                                            /home/ryan/.local/share/jupyter
                                            /home/ryan/.local/share/flatpak
                                            /home/ryan/.local/share/io.github.clash-verge-rev.clash-verge-rev
                                            /home/ryan/.local/share/feral-interactive
                                            /home/ryan/.local/share/direnv
                                            /home/ryan/.local/share/clash-verge
                                            /home/ryan/.local/share/containers
                                            /home/ryan/.local/share/atuin
                                            /home/ryan/.local/share/Steam
                                            /home/ryan/.local/share/StardewValley
                                            /home/ryan/.local/share/GOG.com
                                            /home/ryan/.local/bin
                                            /home/ryan/.local/pipx
                                            /home/ryan/.kube
                                            /home/ryan/.gradle
                                            /home/ryan/.gnupg
                                            /home/ryan/.kimi
                                            /home/ryan/.ipython
                                            /home/ryan/.gemini
                                            /home/ryan/.docker
                                            /home/ryan/.config/sunshine
                                            /home/ryan/.cursor
                                            /home/ryan/.context7
                                            /home/ryan/.config/remmina
                                            /home/ryan/.config/pulse
                                            /home/ryan/.config/opencode
                                            /home/ryan/.config/obs-studio
                                            /home/ryan/.config/mozc
                                            /home/ryan/.config/nushell
                                            /home/ryan/.config/lutris
                                            /home/ryan/.config/joplin
                                            /home/ryan/.config/heroic
                                            /home/ryan/.config/google-chrome
                                            /home/ryan/.config/gcloud
                                            /home/ryan/.config/freerdp
                                            /home/ryan/.config/blender
                                            /home/ryan/.config/chromium
                                            /home/ryan/.config/LDtk
                                            /home/ryan/.config/Joplin
                                            /home/ryan/.config/Cursor
                                            /home/ryan/.config/Code
                                            /home/ryan/.conda
                                            /home/ryan/.cargo
                                            /home/ryan/.codex
                                            /home/ryan/.cache
                                            /home/ryan/.aws
                                            /home/ryan/.aliyun
                                            /etc/ssh
                                            /etc/secureboot
                                            /etc/nix/inputs
                                            /etc/NetworkManager/system-connections
                                            /etc/agenix
                                            /nix/store
                                            /etc/machine-id
                                            /persistent
                                            /nix
```
