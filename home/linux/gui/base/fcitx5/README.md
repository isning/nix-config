# fcitx5 - IME

## Chinese input

The default Chinese engine remains Rime with Wanxiang.

Wanxiang uses Chinese commas in Chinese punctuation mode, including after numbers. Periods and
colons still support decimal numbers and times. This avoids an uncommitted ASCII comma being joined
to the next pinyin input.

Apply with the desktop's usual deployment command (`just niri` on saika-niri), then log out and back
in to load the new input method packages. If Wanxiang's compiled configuration remains old, use
Rime's **Deploy** action in the tray.

## Available Configurations

- `profile` → Symlink will be created at: `~/.config/fcitx5/profile`
- `config1.db` (Mozc config) → Symlink will be created at: `~/.config/mozc/config1.db`
  - Main changes from the defaults: use half-width for all alphabets, numbers, and punctuation.
  - https://github.com/google/mozc/blob/2.30.5544.102/docs/configurations.md
