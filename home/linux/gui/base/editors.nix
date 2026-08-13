{
  config,
  lib,
  pkgs-master,
  ...
}:

{
  catppuccin.vscode.profiles.default.enable = lib.mkForce false;

  xdg.configFile."Code/User/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/home/linux/gui/base/vscode/conf/settings.json";

  programs.vscode = {
    enable = true;
    package = pkgs-master.vscode.override {
      commandLineArgs = [
        # https://code.visualstudio.com/docs/configure/settings-sync#_recommended-configure-the-keyring-to-use-with-vs-code
        # For use with any package that implements the Secret Service API
        # (for example gnome-keyring, kwallet5, KeepassXC)
        "--password-store=gnome-libsecret"
      ];
    };
  };
}
