{ outputs, myvars, ... }:
let
  home = outputs.nixosConfigurations.saika-niri.config.home-manager.users.${myvars.username};
in
{
  ghostty = home.programs.ghostty.enable;
  kitty = home.programs.kitty.enable;
  alacritty = home.programs.alacritty.enable;
  kubernetes = home.programs.k9s.enable && home.programs.kubecolor.enable;
}
