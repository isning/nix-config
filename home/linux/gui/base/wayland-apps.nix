{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # firefox
    nixpaks.firefox
  ];

  programs = {
    # source code: https://github.com/nix-community/home-manager/blob/master/modules/programs/chromium.nix
    google-chrome = {
      enable = true;
      package = if pkgs.stdenv.isAarch64 then pkgs.chromium else pkgs.google-chrome;

      # https://wiki.archlinux.org/title/Chromium#Native_Wayland_support
      commandLineArgs = [
        # enable hardware acceleration - vulkan api
        # "--enable-features=Vulkan"
      ];
    };

    vscode = {
      enable = true;
      package = pkgs.vscode.override {
        isInsiders = false;
        # https://wiki.archlinux.org/title/Wayland#Electron
        commandLineArgs = [
          "--password-store=gnome-libsecret" # use gnome-keyring as password store
        ];
      };
    };
  };
}
