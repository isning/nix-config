{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.features.kubernetes-ai.enable = lib.mkEnableOption "kubernetes-ai";

  config = lib.mkIf config.features.kubernetes-ai.enable {

    home.packages = with pkgs; [
      k8sgpt
      kubectl-ai
    ];
  };
}
