{
  config,
  lib,
  ...
}:
lib.mkIf config.settings.dawarich.enable (
  let
    port = 3000;
    domain = "location.${config.settings.services.domain}";
    # renovate: datasource=docker depName=freikin/dawarich
    version = "1.7.3";
  in
  {
    my.services.dawarich = {
      enable = true;
      name = "Dawarich";
      inherit port;
      description = "Location tracking service";
      internal = {
        enable = true;
        inherit domain;
      };
    };

    sops.templates."dawarich.env" = {
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder."dawarich/databasePassword"}
        DATABASE_PASSWORD=${config.sops.placeholder."dawarich/databasePassword"}
        SECRET_KEY_BASE=${config.sops.placeholder."dawarich/secretKeyBase"}
      '';
    };

    virtualisation.quadlet =
      let
        inherit (config.virtualisation.quadlet) volumes networks;
      in
      {
        volumes = {
          dawarich-db-data = {
            volumeConfig = { };
          };
          dawarich-shared = {
            volumeConfig = { };
          };
          dawarich-public = {
            volumeConfig = { };
          };
          dawarich-watched = {
            volumeConfig = { };
          };
          dawarich-storage = {
            volumeConfig = { };
          };
        };

        networks.dawarich.networkConfig = {
          driver = "bridge";
          podmanArgs = [ "--interface-name=dawarich" ];
        };

        containers.dawarich-redis = {
          containerConfig = {
            image = "docker.io/valkey/valkey:9.1@sha256:50b70cdef934d4b6a4aced5579ac3e3a4a34f36a045851bb7a3306ead1931d27";
            exec = "redis-server --save 900 1 --save 300 10 --appendonly no";
            networks = [ networks.dawarich.ref ];
            networkAliases = [ "dawarich_redis" ];
            volumes = [
              "${volumes.dawarich-shared.ref}:/data"
            ];
            healthCmd = "redis-cli --raw incr ping";
            notify = "healthy";
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        containers.dawarich-db = {
          containerConfig = {
            image = "postgis/postgis:17-3.5-alpine";
            shmSize = "1G";
            networks = [ networks.dawarich.ref ];
            networkAliases = [ "dawarich_db" ];
            environments = {
              POSTGRES_USER = "postgres";
              POSTGRES_DB = "dawarich_development";
            };
            environmentFiles = [ config.sops.templates."dawarich.env".path ];
            volumes = [
              "${volumes.dawarich-db-data.ref}:/var/lib/postgresql/data"
              "${volumes.dawarich-shared.ref}:/var/shared"
            ];
            healthCmd = "pg_isready -U postgres -d dawarich_development";
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            Requires = [ "dawarich-redis.service" ];
            After = [ "dawarich-redis.service" ];
          };
        };

        containers.dawarich-app = {
          containerConfig = {
            image = "freikin/dawarich:${version}";
            exec = "web-entrypoint.sh bin/rails server -p ${toString port} -b ::";
            publishPorts = [ "${toString port}:${toString port}" ];
            networks = [ networks.dawarich.ref ];
            volumes = [
              "${volumes.dawarich-public.ref}:/var/app/public"
              "${volumes.dawarich-watched.ref}:/var/app/tmp/imports/watched"
              "${volumes.dawarich-storage.ref}:/var/app/storage"
              "${volumes.dawarich-db-data.ref}:/dawarich_db_data"
            ];
            environmentFiles = [ config.sops.templates."dawarich.env".path ];
            environments = {
              RAILS_ENV = "production";
              REDIS_URL = "redis://dawarich_redis:6379";
              DATABASE_HOST = "dawarich_db";
              DATABASE_PORT = "5432";
              DATABASE_USERNAME = "postgres";
              DATABASE_NAME = "dawarich_development";
              APPLICATION_HOSTS = "localhost,::1,127.0.0.1,nixnest,${domain}";
              TIME_ZONE = "Europe/Berlin";
              APPLICATION_PROTOCOL = "http";
              PROMETHEUS_EXPORTER_ENABLED = "false";
              PROMETHEUS_EXPORTER_HOST = "0.0.0.0";
              PROMETHEUS_EXPORTER_PORT = "9394";
              RAILS_LOG_TO_STDOUT = "true";
              SELF_HOSTED = "true";
              STORE_GEODATA = "true";
            };
            healthCmd = "wget -qO - http://127.0.0.1:${toString port}/api/v1/health | grep -q '\"status\"\\s*:\\s*\"ok\"'";
          };
          serviceConfig = {
            Restart = "on-failure";
          };
          unitConfig = {
            Requires = [
              "dawarich-db.service"
              "dawarich-redis.service"
            ];
            After = [
              "dawarich-db.service"
              "dawarich-redis.service"
            ];
          };
        };

        containers.dawarich-sidekiq = {
          containerConfig = {
            image = "freikin/dawarich:${version}";
            exec = "sidekiq-entrypoint.sh sidekiq";
            networks = [ networks.dawarich.ref ];
            volumes = [
              "${volumes.dawarich-public.ref}:/var/app/public"
              "${volumes.dawarich-watched.ref}:/var/app/tmp/imports/watched"
              "${volumes.dawarich-storage.ref}:/var/app/storage"
            ];
            environmentFiles = [ config.sops.templates."dawarich.env".path ];
            environments = {
              RAILS_ENV = "production";
              REDIS_URL = "redis://dawarich_redis:6379";
              DATABASE_HOST = "dawarich_db";
              DATABASE_PORT = "5432";
              DATABASE_USERNAME = "postgres";
              DATABASE_NAME = "dawarich_development";
              APPLICATION_HOSTS = "localhost,::1,127.0.0.1,nixnest,${domain}";
              BACKGROUND_PROCESSING_CONCURRENCY = "5";
              APPLICATION_PROTOCOL = "http";
              PROMETHEUS_EXPORTER_ENABLED = "false";
              PROMETHEUS_EXPORTER_HOST = "0.0.0.0";
              PROMETHEUS_EXPORTER_PORT = "9394";
              RAILS_LOG_TO_STDOUT = "true";
              SELF_HOSTED = "true";
              STORE_GEODATA = "true";
            };
            healthCmd = "pgrep -f sidekiq";
          };
          serviceConfig = {
            Restart = "on-failure";
          };
          unitConfig = {
            Requires = [
              "dawarich-app.service"
              "dawarich-db.service"
              "dawarich-redis.service"
            ];
            After = [
              "dawarich-app.service"
              "dawarich-db.service"
              "dawarich-redis.service"
            ];
          };
        };
      };
  }
)
