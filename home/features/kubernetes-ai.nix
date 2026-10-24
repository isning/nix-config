{ pkgs, ... }:
{
  home.packages = with pkgs; [
    k8sgpt
    kubectl-ai
  ];
}
