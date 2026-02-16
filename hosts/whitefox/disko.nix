# Disko configuration converted from saika's hardware-configuration.nix
# This uses LUKS encryption + btrfs with multiple subvolumes
# and tmpfs as root for a stateless system (impermanence/preservation)
{
  pkgs,
  lib,
  disko,
  ...
}:
{
  imports = [
    disko.nixosModules.disko
  ];

  disko.devices = {
    # tmpfs root for stateless system
    nodev = {
      "/" = {
        fsType = "tmpfs";
        # set mode to 755, otherwise systemd will set it to 777, which cause problems.
        # relatime: Update inode access times relative to modify or change time.
        mountOptions = [
          "mode=755"
          "relatime"
        ];
      };
    };

    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Fanxiang_S790_1TB_FXS790244362113";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1024M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted-nixos";

                # LUKS2 format options matching:
                # cryptsetup luksFormat --type luks2 --cipher aes-xts-plain64 \
                #   --hash sha512 --iter-time 5000 --key-size 256 \
                #   --pbkdf argon2id --use-random --verify-passphrase
                extraFormatArgs = [
                  "--type=luks2"
                  "--cipher=aes-xts-plain64"
                  "--hash=sha512"
                  "--iter-time=5000"
                  "--key-size=256"
                  "--pbkdf=argon2id"
                  "--use-random"
                ];

                # Interactive password entry (recommended)
                # disko will prompt for passphrase during installation
                askPassword = true;

                # Alternatively, use a temporary password file for automated install:
                # 1. Create password file: echo -n "your-passphrase" > /tmp/luks.key
                # 2. Uncomment the line below:
                # passwordFile = "/tmp/luks.key";

                settings = {
                  allowDiscards = true;
                  bypassWorkqueues = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    # btrfs top-level subvolume (id=5) for accessing all subvolumes
                    "/" = {
                      mountpoint = "/btr_pool";
                      mountOptions = [ "subvolid=5" ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress-force=zstd:1"
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
                    "@swap" = {
                      mountpoint = "/swap";
                      mountOptions = [ "ro" ];
                      # Note: swapfile setup requires additional configuration
                      # The swapfile remount in read-write mode needs to be handled
                      # separately as disko doesn't directly support this pattern
                      swap = {
                        swapfile.size = "64G";
                      };
                    };
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

  fileSystems."/persistent" = {
    # preservation's data is required for booting.
    neededForBoot = true;
  };
}
