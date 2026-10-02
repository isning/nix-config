# Flake Outputs

`default.nix` composes the active platform directories. Each `src/*.nix` file registers host outputs
through Haumea. Active platforms are `x86_64-linux` and `aarch64-darwin`.

| Platform directory    | Registered hosts         |
| --------------------- | ------------------------ |
| `x86_64-linux/src/`   | `saika-niri`, `whitefox` |
| `aarch64-darwin/src/` | `amiya`                  |

The Saika output also provides an ISO package named `saika-niri`; Whitefox provides `whitefox`.
Whitefox is registered in the Colmena hive.

## Evaluation tests

Tests live in `<platform>/tests/<name>/expr.nix` and `expected.nix`. Run them with:

```bash
just test
```

Tests cover hostnames, Home Manager home directories, and Linux kernel architectures. Hostname
expectations explicitly list active hosts so removing a host cannot silently reduce coverage. Home
Manager expressions discover hosts with the configured user; their expected host lists are explicit,
and servers without Home Manager are excluded.

When adding or retiring a host, update the hostname expectation and, when applicable, the Home
Manager expectation in the same change. Kernel tests cover every registered Linux host.

The `checks.<system>.eval-tests` output is a derivation gated by the same evaluation tests.

```bash
nix build .#checks.x86_64-linux.eval-tests --no-link
nix flake check --no-build
```

`--no-build` evaluates the flake and checks its output schemas. It does not build host systems, run
pre-commit hooks, or boot VMs. The current flake exports no NixOS VM integration tests.
