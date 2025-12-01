{ inputs, ... }:
{
  imports = [
    ../common
    ./configuration.nix
    ./podman.nix
    ./hass.nix
    ./dawarich.nix
    ./spotify.nix
    ./sso.nix
    ./networking.nix
    ./monitoring.nix
    ./git.nix
    ./food.nix
    ./immich.nix
    ./backups.nix
    inputs.sops-nix.nixosModules.sops
    inputs.vscode-server.nixosModules.default
    (
      { ... }:
      {
        services.vscode-server.enable = true;
      }
    )

    inputs.quadlet-nix.nixosModules.quadlet
  ];
}
