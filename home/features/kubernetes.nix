{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.features.kubernetes.enable = lib.mkEnableOption "kubernetes";

  config = lib.mkIf config.features.kubernetes.enable {

    home.packages = with pkgs; [
      kubectl
      kubectx # kubectx & kubens
      kubie # same as kubectl-ctx, but per-shell (won’t touch kubeconfig).
      kubectl-view-secret # kubectl view-secret
      kubectl-tree # kubectl tree
      kubectl-node-shell # exec into node
      kubepug # kubernetes pre upgrade checker
      kubectl-cnpg # cloudnative-pg's cli tool
      kubelogin-oidc # kubectl plugin for OIDC authentication

      kubebuilder
      istioctl
      clusterctl # for kubernetes cluster-api
      kubevirt # virtctl
      kubernetes-helm
      fluxcd
      # argocd

    ];

    home.shellAliases.k = "kubectl";
    programs.nushell.shellAliases.k = "kubectl";
    programs.nushell.extraConfig = lib.mkAfter ''
      # NU_LIB_DIRS is configured by the shared shell module.
      use modules/argx
      use modules/lg *
      use modules/kubernetes *
    '';

    programs.k9s.enable = true;
    catppuccin.k9s.transparent = true;

    programs.kubecolor = {
      enable = true;
      enableAlias = true;
    };
  };
}
