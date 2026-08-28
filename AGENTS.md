# AGENTS.md

## agent-browser — Browser Automation & Web (preferred for browsing/search)

Use agent-browser for fetching pages, searching the web, and interactive browsing. The browser persists via a daemon, so chain commands with &&. Prefer this over the searxng MCP.

Common usage:

```bash
agent-browser read https://example.com # agent-readable page text
agent-browser open example.com && agent-browser snapshot -i # navigate + interactive elements
agent-browser open https://duckduckgo.com/?q=nix+flake+blueprint && agent-browser read # search
agent-browser fill @e3 "text" && agent-browser click @e2 # interact via refs
agent-browser screenshot --full # full-page screenshot
agent-browser chat "open google.com and search for cats" # one-shot AI driving - currently not available
```

Load usage patterns with `agent-browser skills get core --full` before complex flows - be careful, this is a very large document.

## RTK

RTK is an agent-focused binary which makes common command outputs shorter. Use it before any `git`, `cargo`, `docker` or similar commands (package managers, for example).

Usage examples:

```bash
rtk git status
rtk git log
rtk cargo check
rtk cargo test
```

RTK can also be used for reading files, listing directories, grepping and diffing - in case you find this useful, these are the examples:

```bash
rtk ls .                        # Compact directory listing
rtk read file.rs                # Smart file reading
rtk read file.rs -l aggressive  # Signatures only (strips bodies)
rtk smart file.rs               # 2-line heuristic code summary
rtk find "*.rs" .               # Compact find results
rtk grep "pattern" .            # Grouped search results
rtk diff file1 file2            # Condensed diff (exit 1 if files differ)
```

Prefer built-in tools over the rtk command line equivalents. More documentation is available here: https://github.com/rtk-ai/rtk

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
