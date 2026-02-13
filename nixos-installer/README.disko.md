# Nix Environment Setup for general disko used host

> :red_circle: **IMPORTANT**: **Once again, you should NOT deploy this flake directly on your
> machine :exclamation: Please write your own configuration from scratch, and use my configuration
> and documentation for reference only.**

This flake prepares a Nix environment for setting my laptop [/hosts/saika](/hosts/saika/)(in main
flake) up on a new machine.

## Why an extra flake is needed?

The configuration of the main flake, [/flake.nix](/flake.nix), is heavy, and it takes time to debug
& deploy. This simplified flake is tiny and can be deployed very quickly, it helps me to:

1. Adjust & verify my `hardware-configuration.nix` modification quickly before deploying the main
   flake.
2. Test some new filesystem related features on a NixOS virtual machine, such as preservation,
   Secure Boot, TPM2, Encryption, etc.

## Steps to Deploying this flake

First, create a USB install medium from NixOS's official ISO image and boot from it.

### 1. Partition & Install NixOS via Disko

> https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning

> [dm-crypt/Encrypting an entire system - Arch Wiki](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system)

> [Frequently asked questions (FAQ) - cryptsetup](https://gitlab.com/cryptsetup/cryptsetup/wikis/FrequentlyAskedQuestions)

Securing a root file system is where dm-crypt excels, feature and performance-wise. An encrypted
root file system protects everything on the system, it make the system a black box to the attacker.

1. The EFI system partition(ESP) must be left unencrypted, and is mounted at `/boot`
   1. Since the UEFI firmware can only load boot loaders from unencrypted partitions.
2. Secure Boot is enabled, everything in ESP is signed.
3. The BTRFS file system with subvolumes is used for the root partition, and the swap area is a
   swapfile on a dedicated BTRFS subvolume, thus the swap area is also encrypted.

And the boot flow is:

1. The UEFI firmware loads the boot loader from the ESP(`/boot`).
2. The boot loader loads the kernel and initrd from the ESP(`/boot`).
3. **The initrd prompts for the passphrase to unlock the root partition**.
4. The initrd unlocks the root partition and mounts it at `/`.
5. The initrd continues the boot process, and hands over the control to the kernel.

The disk layout is configured in `hosts/<hostname>/disko-config/disko-fs.nix`:

- **ESP (EFI System Partition)**: 512MB, FAT32, mounted at `/boot`
- **LUKS2 encrypted partition**: Rest of the disk, containing BTRFS with subvolumes
  - LUKS2 settings: `aes-xts-plain64`, `sha512`, `argon2id`, `key-size=256`
- **tmpfs root**: `/` is a tmpfs for stateless system (preservation/impermanence)

BTRFS subvolumes inside the encrypted partition:

- `@nix` → `/nix` (Nix store)
- `@guix` → `/gnu` (Guix store, optional)
- `@persistent` → `/persistent` (persistent data)
- `@snapshots` → `/snapshots` (btrfs snapshots)
- `@tmp` → `/tmp` (temporary files)
- `@swap` → `/swap` (swapfile)

Clone the repository and install via disko:

```bash
# enter an shell with git/vim/ssh-agent available
nix-shell -p git vim

# clone this repository
git clone https://github.com/isning/nix-config.git
cd nix-config/nixos-installer

# Option 1: One-line install with disko-install
# This will prompt for LUKS passphrase interactively
#
# NOTE: Using disko-install may cause 'no space left on device' errors on small RAM or tmpfs root systems.
# This is because disko-install downloads all build outputs to /nix/store (in RAM/tmpfs),
# while nixos-install downloads directly to /mnt/nix/store (the target disk).
# See: https://github.com/nix-community/disko/issues/947
# If you encounter space issues, use Option 2 below.
sudo nix run --experimental-features "nix-command flakes" 'github:nix-community/disko#disko-install' -- \
  --write-efi-boot-entries --disk main /dev/nvme0n1 --flake .#whitefox

# if you want to use a cache mirror, run this command instead
sudo nix run --experimental-features "nix-command flakes" 'github:nix-community/disko#disko-install' \
  --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org/" -- \
  --write-efi-boot-entries --disk main /dev/nvme0n1 --flake .#whitefox \
  --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org/"

# Option 2: Step-by-step installation
## 2a. Partition & format disk via disko (will prompt for LUKS passphrase)
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko --flake .#whitefox

## 2b. Install NixOS
# NOTE: the root password you set here will be discarded when reboot
sudo nixos-install --root /mnt --no-root-password --show-trace --verbose --flake .#whitefox

# if you want to use a cache mirror, run this command instead
sudo nixos-install --root /mnt --no-root-password --show-trace --verbose --flake .#whitefox \
  --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org/"
```

Now, the disk status should be:

```bash
# show disk status
$ lsblk
nvme0n1           259:0    0   1.8T  0 disk
├─nvme0n1p1       259:2    0   512M  0 part  /mnt/boot
└─nvme0n1p2       259:3    0   1.8T  0 part
  └─crypted-nixos 254:0    0   1.8T  0 crypt /mnt/swap
                                             /mnt/persistent
                                             /mnt/snapshots
                                             /mnt/nix
                                             /mnt/tmp
                                             /mnt/btr_pool

# show swap status
$ swapon -s
Filename				Type		Size		Used		Priority
/mnt/swap/swapfile                      file		50331648	0		-2
```

### 2. Post-installation Setup

```bash
# enter into the installed system, check password & users
# `su isning` => `sudo -i` => enter user's password => successfully login
# if login failed, check the password you set in install-1, and try again
nixos-enter

# NOTE: DO NOT skip this step!!!
# copy the essential files into /persistent
# otherwise the / will be cleared and data will lost
## NOTE: preservation just create links from / to /persistent
##       We need to copy files into /persistent manually!!!
mkdir -p /persistent/etc/ssh
mv /etc/machine-id /persistent/etc/
mv /etc/ssh/* /persistent/etc/ssh/

# Create user home directory in persistent storage
mkdir -p /persistent/home/isning
chown -R isning:isning /persistent/home/isning

# Exit nixos-enter
exit

# sync the disk, unmount the partitions, and close the encrypted device
sync
swapoff /mnt/swap/swapfile
umount -R /mnt
cryptsetup close /dev/mapper/crypted-nixos
reboot
```

And then reboot.

## Deploying the main flake's NixOS configuration

After rebooting, we need to generate a new SSH key for the new machine, and add it to GitHub, so
that the new machine can pull my private secrets repo:

```bash
# 1. Generate a new SSH key with a strong passphrase
ssh-keygen -t ed25519 -a 256 -C "isning@whitefox" -f ~/.ssh/whitefox
# 2. Add the ssh key to the ssh-agent, so that nixos-rebuild can use it to pull my private secrets repo.
ssh-add ~/.ssh/whitefox
```

Then follow the instructions in [../secrets/README.md](../secrets/README.md) to rekey all my secrets
with the new host's system-level SSH key(`/etc/ssh/ssh_host_ed25519_key`), so that agenix can
decrypt them automatically on the new host when I deploy my NixOS configuration.

After all these steps, we can finally deploy the main flake's NixOS configuration by:

```bash
sudo mv /etc/nixos ~/nix-config
sudo chown -R isning:isning ~/nix-config

cd ~/nix-config

# deploy the configuration via Justfile
just local
```

Finally, to enable secure boot, follow the instructions in
[lanzaboote - Quick Start](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)
and
[nix-config/ai/secure-boot.nix](https://github.com/ryan4yin/nix-config/blob/main/hosts/idols_ai/secureboot.nix)

## Change LUKS2's passphrase

```bash
# test the old passphrase
sudo cryptsetup --verbose open --test-passphrase /path/to/dev/

# change the passphrase
sudo cryptsetup luksChangeKey /path/to/dev/

# test the new passphrase
sudo cryptsetup --verbose open --test-passphrase /path/to/dev/
```
