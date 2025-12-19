{
  pkgs,
  ...
}:
{
  services.printing = {
    enable = true;
    drivers = with pkgs; [ hplip ];
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "HP_LaserJet_1010";
        description = "HP LaserJet 1010";
        location = "Home";
        deviceUri = "hp:/usb/hp_LaserJet_1010?serial=00CNFT009375"; # usb://HP/LaserJet%201010?serial=00CNFT009375
        model = "drv:///hp/hpcups.drv/hp-laserjet_1010.ppd";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];
  };
}
