# AGENTS.md

## Directory Structure

```
nix/
├── hosts/           # Host configs (nixlaptop, nixnest, nixda)
├── modules/
│   ├── home/        # Home Manager modules
│   └── nixos/       # NixOS modules
├── packages/        # packages (blog-builder, nix-update-server)
├── secrets/         # SOPS-encrypted secrets
└── devshell.nix
```

## mcp-nixos tool

The MCP nixos tool can search for Home Manager and NixOS packages / options. Make sure that, when defining an option, that the specified values / format exactly matches what MCP nixos expects.

## Commands

Do not execute commands on your own, only tell the user which commands you want them to execute.
Subagents especially cannot execute commands at all.

### Nix

| Command | Description |
|---------|-------------|
| `nix flake check` | Validate entire flake. Very expensive, only use if strictly asked for |
| `nix build .#<package>` | Build a package |
| `nixos-rebuild dry-build --flake .#<host>` | Test build (no switch) |
| `nixos-rebuild build --flake .#<host>` | Build without switching |
| `nix develop` | Enter devshell |

### Rust (run in `nix/packages/<name>/`)

| Command | Description |
|---------|-------------|
| `cargo check` | Fast compile check |
| `cargo clippy --all-targets` | Lint all targets |
| `cargo test` | Run all tests |
| `cargo test <test_name>` | Run a single test |
| `cargo run` | Run binary |
| `bacon` | Watch-mode check |
| `bacon test` | Watch-mode testing |

## Code Style

### Nix

- **Indentation**: 2 spaces, LF line endings, trailing newline
- **Trailing commas**: Always in lists and attrsets
- **Args**: `{ pkgs, lib, ... }:` pattern
- **Imports**: Group `imports = [...]` at top
- **Naming**: `kebab-case` files, `camelCase` options
- **Options**: Use `mkEnableOption` for booleans with descriptions
- **Validation**: Use `config.assertions` with descriptive messages

### Rust

- **Edition**: 2024
- **Formatting**: `rustfmt` defaults
- **Naming**: `snake_case` functions/vars, `PascalCase` types
- **Errors**: Return `Result<T, String>` with descriptive messages
- **Imports**: std, then external crates, then local
- **Structs**: `#[derive(Debug, Deserialize, Serialize, PartialEq, Eq)]`
- **Tests**: `similar_asserts::assert_eq`, `Result<(), String>` return
