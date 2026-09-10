{ lib, ... }:

_: prev:
lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  google-chrome = prev.google-chrome.override {
    gtk3 = prev.gtk3.overrideAttrs (old: {
      # FIXME(nixpkgs): Remove this backport once packaged GTK includes
      # https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/10014.
      patches = (old.patches or [ ]) ++ [ ./gtk3-monitor-finalize.patch ];
    });
  };
}
