# AGENTS.md

## Directory Structure

The config uses the **dendritic / den** pattern (https://den.denful.dev/). Everything
lives under `modules/`, which is imported by `import-tree` in `flake.nix`. Each file
defines one or more **aspects** (`den.aspects.<name>`) that bundle NixOS, home-manager
and package config for a single concern.

```
modules/
├── hosts/                  # Per-host aspects (e.g. nixlaptop/configuration.nix)
├── apps/                   # Per-app aspects (e.g. apps/git.nix)
├── packages/               # Flake package outputs (e.g. packages/nix-update-server/)
├── den.nix                 # Entrypoint: hosts/users schema + global aspect includes
├── outputs.nix             # Flake output wiring
├── emilia.nix              # The emilia user aspect
├── secrets.nix             # SOPS secrets aspect
└── <concern>.nix           # One file per aspect (audio, niri, graphical, ...)

secrets.yaml               # SOPS-encrypted secrets (repo root)
secrets/                   # Raw secret material
secret-nix-config/         # Git submodule
```

There are more detailed instructions depending on what you are working on:

- [AGENTS-NIX.md](AGENTS-NIX.md) for Nix-specific agents
- [AGENTS-RUST.md](AGENTS-RUST.md) for Rust-specific agents

## Downloading files

User-provided references can be very large files, of which only a part is necessary for completion of the task. When a specific line is provided, only download that specific line and some context around it, for example by using curl like this: `curl -s https://raw.githubusercontent.com/...RepositoryApi.java | sed -n 5,10p` (returns only lines 5-10).
