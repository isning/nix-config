{ config, lib, ... }:
{
  services.coredns = {
    enable = true;
    config = ''
      prod.ingress.internal.isning.moe staging.ingress.internal.isning.moe kubevirt-lab-1.ingress.internal.isning.moe {
          bind 169.254.53.53
          forward . /run/systemd/resolve/resolv.conf
          errors
      }

      kubevirt-lab-1.isning.moe kubevirt-lab-1.ingress.isning.moe {
          bind 169.254.53.53
          template IN ANY {
              answer "{{ .Name }} 60 IN CNAME kubevirt-lab-1.ingress.internal.isning.moe."
          }
          forward . /run/systemd/resolve/resolv.conf
          errors
      }

      staging.isning.moe staging.ingress.isning.moe {
          bind 169.254.53.53
          template IN ANY {
              answer "{{ .Name }} 60 IN CNAME staging.ingress.internal.isning.moe."
          }
          forward . /run/systemd/resolve/resolv.conf
          errors
      }

      harbor.isning.moe logto.isning.moe {
          bind 169.254.53.53
          template IN ANY {
              answer "{{ .Name }} 60 IN CNAME prod.ingress.internal.isning.moe."
          }
          forward . /run/systemd/resolve/resolv.conf
          errors
      }

      isning.moe {
          bind 169.254.53.53
          forward . /run/systemd/resolve/resolv.conf
          errors
      }
    '';
  };

  systemd.services.coredns = {
    after = [
      "network-online.target"
      "systemd-networkd.service"
    ];
    wants = [ "network-online.target" ];
  };

  systemd.network = {
    enable = true;

    netdevs."10-coredns" = {
      netdevConfig = {
        Kind = "dummy";
        Name = "coredns0";
      };
    };

    networks."10-coredns" = {
      matchConfig.Name = "coredns0";
      address = [ "169.254.53.53/32" ];
      dns = [ "169.254.53.53" ];
      domains = [ "~isning.moe" ];
      linkConfig = {
        ActivationPolicy = "always-up";
      };
    };
  };

  services.resolved.enable = true;
}
