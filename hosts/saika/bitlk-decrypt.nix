{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  environment.etc."crypttab".text = ''
    crypted-windows /dev/disk/by-uuid/f490736e-cd2f-45c3-8637-53bb227213fa ${
      config.age.secrets."saika-bitlk-crypt-keys/YMTC-3-2E9FEE63-8BBA-4CCA-89E4-CB8D0E7EB084.BEK".path
    } bitlk nofail
    crypted-data /dev/disk/by-uuid/38f69859-b384-4420-b6b0-5ef377892129 ${
      config.age.secrets."saika-bitlk-crypt-keys/YMTC-5-F13C1B91-772E-499F-A014-4A7C8D8A1EE1.BEK".path
    } bitlk nofail
    crypted-data_2 /dev/disk/by-uuid/7413b5bc-f2b9-4670-a931-eeaf2af67095 ${
      config.age.secrets."saika-bitlk-crypt-keys/FANX-2-2945A11B-7C4E-415D-A27C-4416A856DD63.BEK".path
    } bitlk nofail
  '';

  fileSystems."/mnt/windows" = {
    device = "/dev/mapper/crypted-windows";
    fsType = "ntfs3";
    options = [
      "nofail"
      "ro"
      "windows_names"
      "uid=0"
      "gid=0"
      "dmask=007"
      "fmask=117"
    ];
  };

  fileSystems."/mnt/data" = {
    device = "/dev/mapper/crypted-data";
    fsType = "ntfs3";
    options = [
      "nofail"
      "windows_names"
      "uid=1000"
      "gid=100"
      "dmask=007"
      "fmask=007"
    ];
  };

  fileSystems."/mnt/data_2" = {
    device = "/dev/mapper/crypted-data_2";
    fsType = "ntfs3";
    options = [
      "nofail"
      "windows_names"
      "uid=1000"
      "gid=100"
      "dmask=007"
      "fmask=007"
    ];
  };
}
