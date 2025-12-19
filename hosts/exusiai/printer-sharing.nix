{
  pkgs,
  ...
}:
{
  services.printing = {
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    browsing = true;
    defaultShared = true;
    openFirewall = true;
  };

  services.samba = {
    enable = true;
    package = pkgs.sambaFull;
    openFirewall = true;
    settings = {
      global = {
        "load printers" = "yes";
        "printing" = "cups";
        "printcap name" = "cups";
      };
      "printers" = {
        "comment" = "All Printers";
        "path" = "/var/spool/samba";
        "public" = "yes";
        "browsable" = "yes";
        # to allow user 'guest account' to print.
        "guest ok" = "yes";
        "writable" = "no";
        "printable" = "yes";
        "create mode" = 0700;
      };
    };
  };
  systemd.tmpfiles.rules = [
    "d /var/spool/samba 1777 root root -"
  ];
}
