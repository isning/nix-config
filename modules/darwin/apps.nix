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

  # Homebrew Mirror
  # NOTE: is only useful when you run `brew install` manually! (not via nix-darwin)
  homebrew_mirror_env = {
    # tuna mirror
    # HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
    # HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
    # HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
    # HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
    # HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";

    # bfsu mirror
    HOMEBREW_API_DOMAIN = "https://mirrors.bfsu.edu.cn/homebrew-bottles/api";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.bfsu.edu.cn/homebrew-bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.bfsu.edu.cn/git/homebrew/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.bfsu.edu.cn/git/homebrew/homebrew-core.git";
    HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";

    # nju mirror
    # HOMEBREW_API_DOMAIN = "https://mirror.nju.edu.cn/homebrew-bottles/api";
    # HOMEBREW_BOTTLE_DOMAIN = "https://mirror.nju.edu.cn/homebrew-bottles";
    # HOMEBREW_BREW_GIT_REMOTE = "https://mirror.nju.edu.cn/git/homebrew/brew.git";
    # HOMEBREW_CORE_GIT_REMOTE = "https://mirror.nju.edu.cn/git/homebrew/homebrew-core.git";
    # HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
  };

  local_proxy_env = {
    # HTTP_PROXY = "http://127.0.0.1:7890";
    # HTTPS_PROXY = "http://127.0.0.1:7890";
  };

  homebrew_env_script = lib.attrsets.foldlAttrs (
    acc: name: value:
    acc + "\nexport ${name}=${value}"
  ) "" (homebrew_mirror_env // local_proxy_env);
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
      casks.firefox
      casks.ghostty
      casks.siyuan
      casks.telegram
      casks.qq
      casks.moonlight
      casks.iina
      casks.stats
      casks.neteasemusic
      casks.insomnia
      vscode # Includes the code CLI.
      wget
      aria2
      wireguard-tools
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
    }
    # Set variables for you to manually install homebrew packages.
    // homebrew_mirror_env;

    # Set environment variables for nix-darwin before run `brew bundle`.
    system.activationScripts.homebrew.text = lib.mkBefore ''
      echo >&2 '${homebrew_env_script}'
      ${homebrew_env_script}
    '';

    # Create /etc/zshrc that loads the nix-darwin environment.
    # this is required if you want to use darwin's default shell - zsh
    programs.zsh.enable = true;
    environment.shells = [
      pkgs.zsh
      pkgs.nushell # my custom shell
    ];

    # homebrew need to be installed manually, see https://brew.sh
    # https://github.com/LnL7/nix-darwin/blob/master/modules/homebrew.nix
    homebrew = {
      enable = true; # disable homebrew for fast deploy

      onActivation = {
        autoUpdate = true; # Fetch the newest stable branch of Homebrew's git repo
        upgrade = true; # Upgrade outdated casks, formulae, and App Store apps
        # 'zap': uninstalls all formulae(and related files) not listed in the generated Brewfile
        # Preserve existing apps and preferences while migrating casks to Nix.
        cleanup = "none";
      };

      # Applications to install from Mac App Store using mas.
      # You need to install all these Apps manually first so that your apple account have records for them.
      # otherwise Apple Store will refuse to install them.
      # For details, see https://github.com/mas-cli/mas
      masApps = {
        # Xcode = 497799835;
        Wechat = 836500024;
        Tailscale = 1475387142;
      };

      # These require installer or service integration beyond copying an app bundle.
      casks = [
        "squirrel-app"
        "clash-verge-rev"
        "wireshark-app"
        "miniforge"
        "macfuse"
      ];
    };
  };
}
