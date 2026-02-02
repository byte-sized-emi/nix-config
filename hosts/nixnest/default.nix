{ inputs, ... }:
{
  imports = [
    ../common
    ../../modules/auto-update.nix
    ../../modules/syncthing
    ./configuration.nix
    ./settings.nix
    ./podman.nix
    ./hass.nix
    ./dawarich.nix
    ./sso.nix
    ./networking.nix
    ./monitoring.nix
    ./git.nix
    ./food.nix
    ./immich.nix
    ./backups.nix
    ./secrets.nix
    ./vaultwarden.nix
    ./homepage.nix
    ./beeper.nix
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
