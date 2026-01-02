{ config, pkgs, ... }:
{
  xdg.configFile = {
    "mozc/config1.db".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/home/linux/gui/base/fcitx5/mozc-config1.db";
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-configtool # GUI for fcitx5
        fcitx5-gtk # gtk im module

        # Chinese
        fcitx5-rime # for flypy chinese input method
        # fcitx5-chinese-addons # we use rime instead

        # Japanese
        # ctrl-i / F7 - convert to takakana
        # ctrl-u / F6 - convert to hiragana
        fcitx5-mozc-ut # Moze with UT dictionary
      ];
      settings.inputMethod = {
        "Groups/0" = {
          "Name" = "Intl";
          "Default Layout" = "us";
          "DefaultIM" = "keyboard-us-altgr-intl";
        };

        "Groups/0/Items/0" = {
          "Name" = "keyboard-us";
          "Layout" = "";
        };

        "Groups/0/Items/1" = {
          "Name" = "keyboard-us-intl";
          "Layout" = "";
        };

        "Groups/0/Items/2" = {
          "Name" = "keyboard-us-altgr-intl";
          "Layout" = "";
        };

        "Groups/1" = {
          "Name" = "Default";
          "Default Layout" = "us";
          "DefaultIM" = "rime";
        };

        "Groups/1/Items/0" = {
          "Name" = "keyboard-us";
          "Layout" = "";
        };

        "Groups/1/Items/1" = {
          "Name" = "rime";
          "Layout" = "";
        };

        "Groups/1/Items/2" = {
          "Name" = "mozc";
          "Layout" = "";
        };

        "GroupOrder" = {
          "0" = "Default";
          "1" = "Intl";
        };
      };
    };
  };
}
