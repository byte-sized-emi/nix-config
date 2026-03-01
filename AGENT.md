# nix flake

This is a nix flake for my homelab. It includes three hosts:
- nixlaptop is my laptop with NixOS on it. It's my main system.
- nixnest is my homelab mini PC, for my internal services
- nixda is my desktop PC, mainly for gaming, doesn't see much work

This flake uses the standard `blueprint` layout for its files. You can find packages inside `nix/packages`, hosts inside `nix/hosts`, common NixOS modules inside `nix/modules/nixos`, and common home-manager modules inside `nix/modules/home`.

## For rust and nix development

Validate your changes when appropriate, using `nix flake check` and `cargo check` or `cargo clippy`.
