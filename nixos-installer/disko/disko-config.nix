{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-diskseq/1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "0M";
              end = "1024M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                # extraArgs = [ "-f" ]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  "/@nix" = {
                    mountOptions = [ "noatime,compress=zstd:1" ];
                    mountpoint = "/nix";
                  };
                  "/@tmp" = {
                    mountOptions = [ "compress=zstd:1" ];
                    mountpoint = "/tmp";
                  };
                  "/@swap" = {
                    mountpoint = "/swap";
                    swap = {
                      swapfile.size = "32G";
                    };
                  };
                  "/@persistent" = {
                    mountOptions = [ "noatime,compress=zstd:1" ];
                    mountpoint = "/persistent";
                  };
                  "/@snapshots" = {
                    mountOptions = [ "noatime,compress=zstd:1" ];
                    mountpoint = "/snapshots";
                  };
                };

                mountpoint = "/partition-root";
              };
            };
          };
        };
      };
    };
  };
}
