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

### How aspects work

- **Registration**: hosts and users are declared in `modules/den.nix` under
  `den.hosts.x86_64-linux.<host>.users.<user>`.
- **Global wiring**: `den.schema.host.includes` and `den.schema.user.includes` apply
  aspects to every host / user (e.g. `<boot>`, `<secrets>`, `<den/define-user>`).
- **Class keys**: an aspect can define `nixos`, `homeManager`, and `packages` keys.
  Context args like `{ host, user, pkgs, config, ... }` are injected automatically.
  `pkgs` (and `host` / `user` context) is only available inside these inner functions —
  the top-level module args only get `{ __findFile, lib, config, inputs, den, ... }`.
- **Git index**: `import-tree` only sees files tracked in the git index. `git add` new
  files before evaluating, or the flake silently omits them (symptoms: missing options /
  assertions, e.g. a host aspect not applied → "The 'fileSystems' option does not specify
  your root file system").
- **Includes**: aspects pull in other aspects via `includes = [ <aspect-name> ... ]`.
  Angle-bracket references resolve to other aspects / den batteries and require the
  `__findFile` argument. Den batteries are called as functions, e.g.
  `(<den/user-shell> "zsh")`, `(<den/unfree> [ "steam" ])`, `(<den/primary-user>)`.
- **User-specific aspects**: `den.aspects.<user>` may branch on `host.hostName` with
  `lib.optionals`.
- **Conditional wiring**: aspects like `<graphical>` and `<ai>` are only included for
  hosts / users that opt in.

## mcp-nixos tool

The MCP nixos tool can search for Home Manager and NixOS packages / options. Make sure that, when defining an option, that the specified values / format exactly matches what MCP nixos expects.

For den-specific options and battery aspects (e.g. `den/unfree`, `den/user-shell`), check
the den documentation: https://den.denful.dev/

## Commands

Do not execute commands on your own, only tell the user which commands you want them to execute.
Subagents especially cannot execute commands at all.

### Nix

| Command                                    | Description                                                           |
| ------------------------------------------ | --------------------------------------------------------------------- |
| `nix flake check`                          | Validate entire flake. Very expensive, only use if strictly asked for |
| `nix build .#<package>`                    | Build a package                                                       |
| `nixos-rebuild dry-build --flake .#<host>` | Test build (no switch)                                                |
| `nixos-rebuild build --flake .#<host>`     | Build without switching                                               |

### Rust (run in `modules/packages/<name>/`)

| Command                      | Description        |
| ---------------------------- | ------------------ |
| `cargo check`                | Fast compile check |
| `cargo clippy --all-targets` | Lint all targets   |
| `cargo test`                 | Run all tests      |
| `cargo test <test_name>`     | Run a single test  |
| `cargo run`                  | Run binary         |
| `bacon`                      | Watch-mode check   |
| `bacon test`                 | Watch-mode testing |

## Code Style

### Nix

- **Indentation**: 2 spaces, LF line endings, trailing newline
- **Trailing commas**: Always in lists and attrsets
- **Args**: top-level module args are `{ __findFile, lib, config, inputs, den, ... }` —
  `pkgs` is NOT available there, only in inner module functions (`nixos = { pkgs, ... }:`,
  `homeManager = { pkgs, ... }:`). Include `__findFile` when using angle-bracket includes,
  and `host` / `user` when context is needed
- **Imports**: Group `imports = [...]` at top
- **Naming**: `kebab-case` files, `camelCase` options, aspects named after their concern
- **Aspects**: `den.aspects.<name> = { includes = [...]; nixos = {...}; homeManager = {...}; }`
- **User/host wiring**: keep it in `den.nix` (`den.hosts`, `den.schema`) or the relevant
  user aspect, not scattered across files
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
