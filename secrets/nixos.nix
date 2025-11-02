{
  lib,
  config,
  pkgs,
  agenix,
  mysecrets,
  myvars,
  ...
}:
with lib;
let
  cfg = config.modules.secrets;

  enabledServerSecrets =
    cfg.server.application.enable
    || cfg.server.network.enable
    || cfg.server.operation.enable
    || cfg.server.kubernetes.enable
    || cfg.server.webserver.enable
    || cfg.server.storage.enable;

  noaccess = {
    mode = "0000";
    owner = "root";
  };
  high_security = {
    mode = "0500";
    owner = "root";
  };
  user_readable = {
    mode = "0500";
    owner = myvars.username;
  };
in
{
  imports = [
    agenix.nixosModules.default
  ];

  options.modules.secrets = {
    desktop.enable = mkEnableOption "NixOS Secrets for Desktops";
    host.saika.enable = mkEnableOption "NixOS Secrets for Saika";

    server.network.enable = mkEnableOption "NixOS Secrets for Network Servers";
    server.application.enable = mkEnableOption "NixOS Secrets for Application Servers";
    server.operation.enable = mkEnableOption "NixOS Secrets for Operation Servers(Backup, Monitoring, etc)";
    server.kubernetes.enable = mkEnableOption "NixOS Secrets for Kubernetes";
    server.webserver.enable = mkEnableOption "NixOS Secrets for Web Servers(contains tls cert keys)";
    server.storage.enable = mkEnableOption "NixOS Secrets for HDD Data's LUKS Encryption";

    preservation.enable = mkEnableOption "whether use preservation and ephemeral root file system";
  };

  config = mkIf (cfg.desktop.enable || enabledServerSecrets) (mkMerge [
    {
      environment.systemPackages = [
        agenix.packages."${pkgs.system}".default
      ];

      # if you changed this key, you need to regenerate all encrypt files from the decrypt contents!
      age.identityPaths =
        if cfg.preservation.enable then
          [
            # To decrypt secrets on boot, this key should exists when the system is booting,
            # so we should use the real key file path(prefixed by `/persistent/`) here, instead of the path mounted by preservation.
            "/persistent/etc/ssh/ssh_host_ed25519_key" # Linux
          ]
        else
          [
            "/etc/ssh/ssh_host_ed25519_key"
          ];

      # secrets that are used by all nixos hosts
      age.secrets = {
        "nix-access-tokens" = {
          file = "${mysecrets}/nix-access-tokens.age";
        }
        # access-token needs to be readable by the user running the `nix` command
        // user_readable;
      };

      assertions = [
        {
          # This expression should be true to pass the assertion
          assertion = !(cfg.desktop.enable && enabledServerSecrets);
          message = "Enable either desktop or server's secrets, not both!";
        }
      ];
    }

    (mkIf cfg.host.saika.enable {
      age.secrets = {
        "saika-bitlk-crypt-key" = {
          file = "${mysecrets}/saika-bitlk-crypt-key.age";
          mode = "0400";
          owner = "root";
        };
      };

      # place secrets in /etc/
      environment.etc = {
        "agenix/saika-bitlk-crypt-key" = {
          source = config.age.secrets."saika-bitlk-crypt-key".path;
          mode = "0400";
          user = "root";
        };
      };
    })

    (mkIf cfg.desktop.enable {
      age.secrets = {
        # ---------------------------------------------
        # no one can read/write this file, even root.
        # ---------------------------------------------

        # .age means the decrypted file is still encrypted by age(via a passphrase)
        #  "ryan4yin-gpg-subkeys.priv.age" = {
        #    file = "${mysecrets}/ryan4yin-gpg-subkeys-2024-01-27.priv.age.age";
        #  }
        #  // noaccess;

        # ---------------------------------------------
        # only root can read this file.
        # ---------------------------------------------

        #  "wg-business.conf" = {
        #    file = "${mysecrets}/wg-business.conf.age";
        #  }
        #  // high_security;

        # ---------------------------------------------
        # user can read this file.
        # ---------------------------------------------

        "ssh-key-backup" = {
          file = "${mysecrets}/ssh-key-backup.age";
        }
        // user_readable;
      };

      # place secrets in /etc/
      environment.etc = {
        "agenix/ssh-key-backup" = {
          source = config.age.secrets."ssh-key-backup".path;
          mode = "0600";
          user = myvars.username;
        };
      };
    })

    (mkIf cfg.server.network.enable {
      age.secrets = {
      };
    })

    (mkIf cfg.server.application.enable {
      age.secrets = {
      };
    })

    (mkIf cfg.server.operation.enable {
      age.secrets = {
      };
    })

    (mkIf cfg.server.kubernetes.enable {
      age.secrets = {
      };
    })

    (mkIf cfg.server.webserver.enable {
      age.secrets = {
      };
    })
  ]);
}
