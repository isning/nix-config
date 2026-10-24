{
  config,
  lib,
  pkgs,
  brew-nix,
  ...
}:
##########################################################################
#
#  Install all apps and packages here.
#
#  NOTE: Your can find all available options in:
#    https://daiderd.com/nix-darwin/manual/index.html
#
#  NOTE：To remove the uninstalled APPs icon from Launchpad:
#    1. `sudo nix store gc --debug` & `sudo nix-collect-garbage --delete-old`
#    2. click on the uninstalled APP's icon in Launchpad, it will show a question mark
#    3. if the app starts normally:
#        1. right click on the running app's icon in Dock, select "Options" -> "Show in Finder" and delete it
#    4. hold down the Option key, a `x` button will appear on the icon, click it to remove the icon
#
# TODO Fell free to modify this file to fit your needs.
#
##########################################################################
let
  casks = brew-nix.packages.${pkgs.stdenv.hostPlatform.system};

in
{
  options.features.desktop-apps.enable = lib.mkEnableOption "desktop-apps";

  config = lib.mkIf config.features.desktop-apps.enable {

    # Install packages from nix's official package repository.
    #
    # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
    environment.systemPackages = with pkgs; [
      neovim
      git
      nushell # my custom shell
      # Vendor binaries packaged by Nix, without running Homebrew.
      casks.betterdisplay
      casks.jordanbaird-ice
      casks.linearmouse
      casks.maccy
      casks.firefox
      casks.ghostty
      casks.siyuan
      casks.telegram
      casks.qq
      casks.wechatwork
      casks.wechat
      casks.feishu
      casks.tencent-meeting
      casks.moonlight
      casks.iina
      casks.stats
      casks.wireshark-app
      (pkgs.callPackage ./packages/neteasemusic.nix { cask = casks.neteasemusic; })
      vscode # Includes the code CLI.
      wget
      aria2
      m-cli
      proxychains-ng
      gnused
      google-chrome
      gnugrep # replacee macos's grep
      gnutar # replacee macos's tar
    ];
    environment.variables = {
      # Fix https://github.com/LnL7/nix-darwin/wiki/Terminfo-issues
      TERMINFO_DIRS = map (path: path + "/share/terminfo") config.environment.profiles ++ [
        "/usr/share/terminfo"
      ];
    };

    # Create /etc/zshrc that loads the nix-darwin environment.
    # this is required if you want to use darwin's default shell - zsh
    programs.zsh.enable = true;
    environment.shells = [
      pkgs.zsh
      pkgs.nushell # my custom shell
    ];

  };
}
