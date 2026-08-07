---
name: blueprint-to-den-migration
description: Migrates the remaining legacy blueprint config in this repo (nix/hosts/*, nix/modules/{nixos,home}, nix/packages) into denful/den aspects under modules/**. Use when converting hosts, users, home modules, or service files into den aspects, or when working with den namespaces (apps, stacks, ...).
---

# Migrating legacy blueprint config to den (this repo)

## Context — groundwork already done, do not redo it

- `flake.nix` already evaluates `modules/**` via `nixpkgs.lib.evalModules` + `inputs.import-tree`; `specialArgs.inputs` is available to every module.
- `modules/den.nix` already wires `__findFile`, `den.hosts`, `den.schema` (host/user includes), the `apps` namespace, and the `emilia` user aspect.
- `modules/outputs.nix` already wires flake package outputs.
- Do **not** touch the den plumbing (flake.nix eval, den.nix schema, import-tree). This skill only covers moving the remaining `nix/` blueprint files into den aspects and wiring them to hosts/users.

Remaining migration targets (check current state — `nixlaptop` is already migrated):

- `nix/hosts/nixda/`, `nix/hosts/nixdort/`, `nix/hosts/nixnest/` — each has `configuration.nix`, `users/emilia.nix`, and host-local files (`settings.nix`, `data.nix`, `networking/`, many per-service files).
- `nix/modules/{nixos,home}/*` not yet converted.
- `nix/packages/linktree/`.

## Core idea

**Rewrite structure, not semantics.** All NixOS / home-manager module content carries over byte-for-byte. Only two things change:

1. **Wrapping**: module files become *aspects*; `imports = [ ./x.nix ]` becomes `includes = [ <x> ]`.
2. **Wiring**: register hosts in `den.nix`, attach aspects via `includes` / `den.schema` includes.

## Structure mapping

| Blueprint (old) | den (new) |
| --- | --- |
| `nix/hosts/<host>/configuration.nix` | `modules/hosts/<host>/configuration.nix` → `den.aspects.<host>` |
| `nix/hosts/<host>/users/<user>.nix` | user aspect (`modules/emilia.nix`) with conditional includes |
| `nix/hosts/<host>/<service>.nix` | service aspect in a dedicated namespace (e.g. `stacks`) |
| `nix/modules/nixos/<concern>.nix` | `modules/<concern>.nix` → `den.aspects.<concern>.nixos` |
| `nix/modules/home/<concern>.nix` | `modules/apps/<concern>.nix` → `apps.<concern>.homeManager` |
| `nix/packages/<pkg>/` | `modules/packages/<pkg>/`, wired via `den.aspects.*.packages` |
| custom `options.*` modules (`settings.nix`, `service.nix`) | `options`/`config` inside the owning aspect's `nixos` key |

## den concepts you need

- **Aspect**: `den.aspects.<name> = { includes = [...]; nixos = {...}; homeManager = {...}; packages = {...}; }`. The `nixos` / `homeManager` blocks are **standard module expressions** — same options as before, same `mkIf`/`mkForce`.
- **Includes ≠ imports**: `includes = [ <aspect> ]` pulls in other aspects. Angle-bracket refs (`<boot>`, `<den/primary-user>`, `<apps/git>`) require `__findFile` in the module args.
- **Context args are real functions**: `nixos = { host, user, config, pkgs, ... }: {...}`. Argument shape drives dispatch — `{ host, ... }` runs at host scope, `{ host, user, ... }` per user. No `specialArgs` / infinite-recursion tricks.
- **Batteries**: reusable aspects referenced as `<den/...>`, e.g. `(<den/user-shell> "zsh")`, `(<den/unfree> [ "pkg" ])`, `<den/primary-user>`, `<den/define-user>`, `<den/hostname>`.
- **Aspect merging**: several files can contribute to the *same* aspect (this repo splits host config across `configuration.nix`, `hardware-configuration.nix`, `secure-boot.nix`, each writing `den.aspects.<host>.nixos`).
- **Host aspects**: `den.aspects.<host>` is applied to that host automatically by the den framework; `den.hosts.<system>.<host>` declares the entity.

## Steps

### 1. Register the host in `modules/den.nix`

```nix
den.hosts.x86_64-linux.nixnest.users.emilia = { };
```

Global aspects from `den.schema.host.includes` apply automatically. Host-specific *shared* aspects go in the host aspect's `includes`.

### 2. Create `modules/hosts/<host>/configuration.nix`

```nix
{ __findFile, ... }:
{
  den.aspects.nixnest = {
    includes = [
      <auto-update>
      <syncthing>
      # ... shared aspects this host needs ...
    ];

    nixos = { pkgs, ... }: {
      # ... host-local NixOS config, copied verbatim ...
      system.stateVersion = "24.11";
    };
  };
}
```

- `hardware-configuration.nix` → sibling file writing `den.aspects.<host>.nixos`, keeping its `modulesPath` import, `fileSystems`, `swapDevices`, `nixpkgs.hostPlatform`.
- Split large host configs into sibling files, each merging into `den.aspects.<host>.nixos` (pattern: `secure-boot.nix` for lanzaboote).
- Copy `system.stateVersion` verbatim from the old config.

### 3. Migrate host-local service files (dedicated namespace)

`nix/hosts/nixnest/*.nix` (forgejo, homeassistant, vaultwarden, immich, mealie, atuin, ntfy, beeper, ...) are self-contained service concerns. Recommended target: `modules/stacks/<service>.nix` defining `stacks.<service> = { nixos = { ... }; }`, referenced as `<stacks/<service>>` from the host aspect's `includes`.

**Creating the `stacks` namespace requires asking the user first** (see Namespaces). Also move the custom option modules they depend on:

- `settings.nix` (`options.settings` — domains, backup intervals) → the host aspect's `nixos` block.
- `service.nix` (`options.my.services` registry + caddy vhost wiring) → the aspect that owns the registry.

### 4. Migrate the user

`modules/emilia.nix` already defines `den.aspects.emilia`; extend it for the other hosts:

```nix
{ __findFile, lib, ... }:
{
  den.aspects.emilia = { host, ... }: {
    includes = [
      (<den/user-shell> "zsh")
      <apps/git>
      <apps/shell>
    ]
    ++ lib.optionals (host.hostName == "nixnest") [
      # ... host-specific aspects for this user ...
    ];

    nixos = { config, pkgs, ... }: { ... };
    homeManager = { pkgs, ... }: { ... };
  };
}
```

- Old per-host `users/<user>.nix` imports → `lib.optionals (host.hostName == "...")` in the user aspect, or `provides.to-users.homeManager` on the host aspect.
- Per-app home concerns belong in the `apps` namespace (see below).

### 5. Migrate remaining shared modules

- `nix/modules/nixos/<concern>.nix` → `modules/<concern>.nix` with `den.aspects.<concern>.nixos = { ... }`. Concepts that apply to every host/user (boot, user, secrets, networking, nixConfig) → `den.schema.host.includes` / `den.schema.user.includes` in `den.nix`.
- `nix/modules/home/<concern>.nix` → `modules/apps/<concern>.nix` as `apps.<concern> = { homeManager = { ... }; }`. Purely per-app concerns (git, shell, browser, email, ...) go in `apps`; whole-desktop / cross-cutting concerns (graphical, ai, anki, fachschaft) stay top-level. When a home module is ambiguous, ask the user.

### 6. Migrate packages

- Move `nix/packages/<pkg>/` → `modules/packages/<pkg>/`.
- Expose via the owning aspect: `modules/packages/auto-update.nix` does `den.aspects.auto-update.packages = { pkgs, ... }: { nix-update-server = ...; }`.
- Flake outputs are already wired in `modules/outputs.nix` (`flakeOutputs.packages` + `den.schema.flake-system.includes`) — just make sure the owning aspect is listed there.

### 7. Validate

Per AGENTS.md, **do not run these yourself** — give them to the user:

- `nixos-rebuild dry-build --flake .#<host>` — primary check
- `nix flake check` — full validation, slow; only if asked
- After a real switch: restart terminals (see pitfalls)

## Namespaces

### What they are

A namespace is a scoped aspect library under `den.ful.<name>`, surfaced to modules as a module arg named after it. Aspects inside it are `apps.git`, `stacks.forgejo`, etc.

### Creating

Register in `modules/den.nix` imports:

```nix
(inputs.den.namespace "apps" false)
```

- `false` → local-only namespace.
- `true` → also export as `flake.denful.<name>`.
- list of sources, e.g. `[ inputs.other-flake true ]` → merge upstream `flake.denful.<name>` and export.

### Populating

Any module file can set the namespace arg:

```nix
{ stacks, ... }:
{
  stacks.forgejo = { nixos = { ... }; };
}
```

### Referencing

- Angle brackets: `includes = [ <stacks/forgejo> ]` (requires `__findFile` in args).
- Direct attr: `stacks.forgejo`.

### Rules for this repo (IMPORTANT)

1. **Always ask the user before creating a new namespace.** Propose the name, list exactly which aspects would live in it, and wait for approval. Never invent one silently.
2. Existing, freely usable namespaces: `apps` (per-app home-manager concerns).
3. **Recommendation — dedicated namespace for larger collections.** When a family of related aspects grows, use a separate namespace instead of top-level files. The server *services* being migrated from `nix/hosts/nixnest/*.nix` (forgejo, homeassistant, vaultwarden, immich, mealie, atuin, ...) are the prime candidate for a `stacks` namespace → `modules/stacks/<svc>.nix`, referenced as `<stacks/<svc>>`.
4. `modules/<concern>.nix` at top level is reserved for single cross-cutting concerns (audio, graphical, boot, secrets, syncthing, ...). If a concern is really a *collection*, propose a namespace (rule 1).

## Pitfalls learned from migrating this repo

1. **User package profile location changes.** den's home-manager integration puts user packages in `~/.nix-profile` (useUserPackages-style) instead of `/etc/profiles/per-user/<user>`. After switching, already-open shells keep the stale PATH → `command not found` (e.g. starship). This is expected, not a bug — restart terminals. If a system profile wasn't bumped, re-run `nixos-rebuild switch --flake .#<host>`.
2. **`nix-env` leftovers.** Imperative installs survive in `~/.nix-profile`. `nix-env -e <pkg>` is safe; the tool usually still comes via `home.packages`. Warn users that future `nix-env` ops clobber the home-manager profile symlink.
3. **Unfree scoping.** `(<den/unfree> [ "attrName" ])` must use exact attr/pname names. Scope it per including aspect, not globally.
4. **`__findFile`** must be in the args attrset of *every* file using `<...>` includes.
5. **Confirm intentional drops** with the user (e.g. `isd`, `libargon2` were deliberately dropped during the nixlaptop migration).
6. **Keep semantics identical** — `system.stateVersion`, `home.stateVersion`, and file contents carry over unchanged.
7. **Watch global-schema includes** — a shared module removed from `den.schema.host.includes` silently stops applying everywhere (this repo's `controller` aspect was pulled out of the global schema). Double-check removals are intended.

## References

- den docs: <https://den.denful.dev/>
- Namespaces: <https://den.denful.dev/guides/namespaces/>
- Angle brackets: <https://den.denful.dev/guides/angle-brackets/>
- Coming from NixOS / home-manager: <https://den.denful.dev/explanation/coming-from/>
- This repo: `AGENTS.md` (structure, style conventions), `modules/den.nix` (wiring), `modules/hosts/nixlaptop/*` (worked examples), `modules/ai/skills/` (this skill).
