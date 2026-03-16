# Disko layout for idols-ai on nvme1n1 (target disk after migration).
# Same structure as current nvme0n1: ESP + LUKS + btrfs with ephemeral root (tmpfs).
#
# Format & mount (from installer or live system):
#   nix run github:nix-community/disko -- --mode disko ./disko-fs.nix
# Mount only (after first format):
#   nix run github:nix-community/disko -- --mode mount ./disko-fs.nix
#
# Use by-id for stability; override device when installing, e.g.:
#   nixos-install --flake .#ai --option disko.devices.disk.nixos-ai.device /dev/nvme1n1
{
  disko,
  ...
}:
{
  imports = [
    disko.nixosModules.disko
  ];

  # Ephemeral root; preservation mounts /persistent for state.
  fileSystems."/persistent".neededForBoot = true;

  disko.devices = {
    # Ephemeral root; relatime and mode=755 so systemd does not set 777.
    nodev."/" = {
      fsType = "tmpfs";
      # set mode to 755, otherwise systemd will set it to 777, which cause problems.
      # relatime: Update inode access times relative to modify or change time.
      mountOptions = [
        "relatime" # Update inode access times relative to modify/change time
        "mode=755"
      ];
    };

    disk.s790-4t = {
      type = "disk";
      # Override at install time if needed: --option disko.devices.disk.nixos-saika.device /dev/nvme1n1
      device = "/dev/disk/by-id/nvme-Fanxiang_S790_4TB_FXS790233910647";
      content = {
        type = "gpt";
        partitions = {
          # EFI system partition; must stay unencrypted for UEFI to load the bootloader.
          ESP = {
            priority = 1;
            name = "ESP";
            start = "1M";
            end = "1025M";
            type = "EF00"; # EF00 = ESP in GPT
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0177" # File mask: 777-177=600 (owner rw-, group/others ---)
                "dmask=0077" # Directory mask: 777-077=700 (owner rwx, group/others ---)
                "noexec,nosuid,nodev" # Security: no execution, ignore setuid, no device nodes
              ];
            };
          };

          data = {
            priority = 2;
            name = "data";
            start = "1074790400B";
            end = "2901275574271B";
            type = "0700"; # msftdata
          };

          # Root partition: LUKS encrypted, then btrfs with subvolumes.
          root = {
            priority = 3;
            size = "100%";
            content = {
              type = "luks";
              name = "crypted-nixos"; # Mapper name; match boot.initrd.luks

              settings = {
                allowDiscards = true; # TRIM for SSDs; slightly less secure, better performance
                bypassWorkqueues = true;
              };
              # Add boot.initrd.luks.devices so initrd prompts for passphrase at boot
              initrdUnlock = true;

              # cryptsetup luksFormat options
              extraFormatArgs = [
                "--type luks2"
                "--cipher aes-xts-plain64"
                "--hash sha512"
                "--iter-time 5000"
                "--key-size 256"
                "--pbkdf argon2id"
                "--use-random" # Block until enough entropy from /dev/random
              ];

              extraOpenArgs = [
                "--timeout 10"
              ];

              # Interactive password entry (recommended)
              # disko will prompt for passphrase during installation
              askPassword = true;

              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Force overwrite if filesystem already exists
                subvolumes = {
                  # Top-level subvolume (id 5); used for btrfs send/receive and snapshots
                  "/" = {
                    mountpoint = "/btr_pool";
                    mountOptions = [ "subvolid=5" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress-force=zstd:1" # Save space and reduce I/O on SSD
                      "noatime"
                    ];
                  };
                  "@guix" = {
                    mountpoint = "/gnu";
                    mountOptions = [
                      "compress-force=zstd:1"
                      "noatime"
                    ];
                  };
                  "@persistent" = {
                    mountpoint = "/persistent";
                    mountOptions = [
                      "compress-force=zstd:1"
                    ];
                  };
                  "@snapshots" = {
                    mountpoint = "/snapshots";
                    mountOptions = [
                      "compress-force=zstd:1"
                    ];
                  };
                  "@tmp" = {
                    mountpoint = "/tmp";
                    mountOptions = [
                      "compress-force=zstd:1"
                    ];
                  };
                  # Swap subvolume read-only; disko creates swapfile and adds swapDevices
                  "@swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = "96G";
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Additional filesystem configuration for swapfile remount
  # This handles the read-write bind mount of swapfile
  fileSystems."/swap/swapfile" = {
    depends = [ "/swap" ];
    device = "/swap/swapfile";
    fsType = "none";
    options = [
      "bind"
      "rw"
    ];
  };
}
