{ outputs, myvars, ... }:
let
  system = outputs.nixosConfigurations.saika-niri.config;
  home = system.home-manager.users.${myvars.username};
  overridden =
    (outputs.nixosConfigurations.saika-niri.extendModules {
      modules = [
        {
          home-manager.users.${myvars.username}.features = {
            kubernetes.enable = false;
            additional-terminals.enable = false;
          };
        }
      ];
    }).config.home-manager.users.${myvars.username};
in
{
  warnings = system.warnings ++ home.warnings;
  role = home.roles.development-workstation.enable;
  featureOverrides = !overridden.programs.k9s.enable && !overridden.programs.kitty.enable;
  ghostty = home.programs.ghostty.enable;
  kitty = home.programs.kitty.enable;
  alacritty = home.programs.alacritty.enable;
  kubernetes = home.programs.k9s.enable && home.programs.kubecolor.enable;
}
