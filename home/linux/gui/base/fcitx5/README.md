# fcitx5 - IME

## Chinese input

The default Chinese engine remains Rime with Wanxiang.

Wanxiang uses Chinese commas in Chinese punctuation mode, including after numbers. Periods and
colons still support decimal numbers and times. This avoids an uncommitted ASCII comma being joined
to the next pinyin input.

Apply with the desktop's usual deployment command (`just niri` on saika-niri), then log out and back
in to load the new input method packages. If Wanxiang's compiled configuration remains old, use
Rime's **Deploy** action in the tray.

## Input method configuration

The Fcitx5 profile is generated from `settings.inputMethod` in `default.nix` and includes Rime and
US keyboard layouts.
