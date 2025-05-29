# Hosts

1. `12kingdoms`:
   1. `shoukei`: NixOS on Macbook Pro 2020 Intel i5, 13.3-inch, 16G RAM + 512G SSD.
1. `darwin`(macOS)
   1. `fern`: MacBook Pro 2022 13-inch M2 16G, mainly for business.
   1. `harmonica`: MacBook Pro 2020 13-inch i5 16G, for personal use.
1. `k8s`: My Kubevirt & Kubernetes Clusters
1. `idols`
   1. `ai`: My main computer, with NixOS + I5-13600KF + RTX 4090 GPU, for gaming & daily use.
   2. `aquamarine`: Kubevirt Virtual Machine.
      - Monitoring(prometheus, grafana, exporters), CI/CD(gitea, runner), homepage, file browser,
        and other services.
   3. `ruby`: Not used now.
   4. `kana`: Not used now.
1. Other aarch64/riscv64 SBCs:
   [ryan4yin/nixos-config-sbc](https://github.com/ryan4yin/nixos-config-sbc)

## How to add a new host

1. Under `hosts/`
   1. Create a new folder under `hosts/` with the name of the new host.
   2. Create & add the new host's `hardware-configuration.nix` to the new folder, and add the new
      host's `configuration.nix` to `hosts/<name>/default.nix`.
   3. If the new host need to use home-manager, add its custom config into `hosts/<name>/home.nix`.
1. Under `outputs/`
   1. Add a new nix file named `outputs/<system-architecture>/src/<name>.nix`.
   2. Copy the content from one of the existing similar host, and modify it to fit the new host.
      1. Usually, you only need to modify the `name` and `tags` fields.
   3. [Optional] Add a new unit test file under `outputs/<system-architecture>/tests/<name>.nix` to
      test the new host's nix file.
   4. [Optional] Add a new integration test file under
      `outputs/<system-architecture>/integration-tests/<name>.nix` to test whether the new host's
      nix config can be built and deployed correctly.
1. Under `vars/networking.nix`
   1. Add the new host's static IP address.
   1. Skip this step if the new host is not in the local network or is a mobile device.
