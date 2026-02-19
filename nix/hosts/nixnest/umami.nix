{ config, ... }:
{
  my.services.umami = {
    enable = true;
    name = "Umami";
    port = config.services.umami.settings.PORT;
    description = "Self-hosted web analytics service";
    external = {
      enable = false;
      domain = "analytics.${config.settings.domain}";
    };
    internal = {
      enable = true;
      domain = "analytics.${config.settings.services.domain}";
    };
  };

  services.umami = {
    enable = true;
    createPostgresqlDatabase = false;
    settings = {
      PORT = 3243;
      HOSTNAME = "127.0.0.1";
      APP_SECRET_FILE = config.sops.secrets."umami/appSecret".path;
      DATABASE_URL_FILE = config.sops.templates."umami/dbUrl".path;
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      volumes = {
        umami-db-data = {
          volumeConfig = { };
        };
      };

      # this is backed up in ./backups.nix
      containers.umami-db = {
        containerConfig = {
          image = "postgres:18-alpine";
          publishPorts = [
            "5444:5432"
          ];
          environmentFiles = [ config.sops.templates."umami/postgresEnvFile".path ];
          environments = {
            POSTGRES_USER = "postgres";
            POSTGRES_DB = "umami";
          };
          volumes = [
            "${volumes.umami-db-data.ref}:/var/lib/postgresql/data"
          ];
        };

        serviceConfig = {
          Restart = "always";
        };
      };
    };
}
