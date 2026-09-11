# 为了不使用默认的 rime-data，改用我自定义的小鹤音形数据，这里需要 override
# 参考 https://github.com/NixOS/nixpkgs/blob/e4246ae1e7f78b7087dce9c9da10d28d3725025f/pkgs/tools/inputmethods/fcitx5/fcitx5-rime.nix
_:
(self: super: {
  # FIXME(nixpkgs): Drop this patch once librime resolves
  # https://github.com/rime/librime/issues/1017 upstream and nixpkgs includes it.
  librime = super.librime.overrideAttrs (
    old:
    self.lib.optionalAttrs self.stdenv.hostPlatform.isLinux {
      patches = (old.patches or [ ]) ++ [ ./caps-lock-sync.patch ];
      doCheck = true;
    }
  );

  rime-data = super.buildEnv {
    name = "rime-data";
    paths = [
      ./my-rime-data
      self.rime-wanxiang
      self.nur.repos.jetcookies.rime-lmdg
    ];
  };

  fcitx5-rime = super.fcitx5-rime.override {
    rimeDataPkgs = [
      self.rime-data
    ];
  };

  # used by macOS Squirrel
  # FIXME: Need to add rime-wanxiang as dependency
  flypy-squirrel = ./my-rime-data;
})
