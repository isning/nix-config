{ pkgs, ... }:
{
  home.packages = with pkgs; [
    podman-compose
    dive # explore docker layers
    lazydocker # Docker terminal UI.
    skopeo # copy/sync images between registries and local storage
    go-containerregistry # provides `crane` & `gcrane`, it's similar to skopeo
    ko # Build Go projects as container images.
  ];
}
