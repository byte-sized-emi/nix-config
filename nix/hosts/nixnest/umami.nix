{ config, ... }:
let
  port = 3243;
in
{
  my.services.umami = {
    enable = true;
    name = "Umami";
    inherit port;
    description = "Self-hosted web analytics service";
    external = {
      enable = true;
      domain = "analytics.${config.settings.domain}";
    };
    internal = {
      enable = false;
      domain = "analytics.${config.settings.services.domain}";
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks;
    in
    {
      volumes = {
        umami-db-data.volumeConfig = { };
      };

      networks = {
        umami.networkConfig = {
          driver = "bridge";
          podmanArgs = [ "--interface-name=umami" ];
        };
      };

      containers.umami = {
        containerConfig = {
          image = "ghcr.io/umami-software/umami:3.0.3";
          publishPorts = [
            "${toString port}:3000"
          ];
          environmentFiles = [ config.sops.templates."umami/envFile".path ];
          networks = [ networks.umami.ref ];
        };
        serviceConfig = {
          Restart = "always";
        };
        unitConfig = {
          After = [ "umami-db.service" ];
          Requires = [ "umami-db.service" ];
        };
      };

      # this is backed up in ./backups.nix
      containers.umami-db = {
        containerConfig = {
          image = "postgres:18-alpine";
          environmentFiles = [ config.sops.templates."umami/postgresEnvFile".path ];
          environments = {
            POSTGRES_USER = "postgres";
            POSTGRES_DB = "umami";
          };
          volumes = [
            "${volumes.umami-db-data.ref}:/var/lib/postgresql/"
          ];
          networks = [ networks.umami.ref ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };
    };
}
