{ config, lib, settings, ... }:
let
  version = "0.25.10";
in if (settings.dawarich.enabled == false)
then { }
else
{
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes;
  in {
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
    containers.dawarich-redis = {
      containerConfig = {
        image = "redis:7.0-alpine";
        entrypoint = "redis-server";
        volumes = [
          "${volumes.dawarich-shared.ref}:/data"
        ];
        # healthcheck = {
        #   test = [ "CMD" "redis-cli" "--raw" "incr" "ping" ];
        #   interval = "10s";
        #   retries = 5;
        #   startPeriod = "30s";
        #   timeout = "10s";
        # };
      };
      serviceConfig = {
        Restart = "always";
      };
    };

    # PostgreSQL service
    containers.dawarich-db = {
      containerConfig = {
        image = "postgis/postgis:17-3.5-alpine";
        environments = {
          POSTGRES_USER = "postgres";
          POSTGRES_PASSWORD = "password";
          POSTGRES_DB = "dawarich_development";
        };
        volumes = [
          "${volumes.dawarich-db-data.ref}:/var/lib/postgresql/data"
          "${volumes.dawarich-shared.ref}:/var/shared"
        ];
        # healthcheck = {
        #   test = [ "CMD-SHELL" "pg_isready -U postgres -d dawarich_development" ];
        #   interval = "10s";
        #   retries = 5;
        #   startPeriod = "30s";
        #   timeout = "10s";
        # };
      };
      serviceConfig = {
        Restart = "always";
      };
    };

    # Main application service
    containers.dawarich-app = {
      containerConfig = {
        image = "freikin/dawarich:${version}";
        exec = [ "bin/rails" "server" "-p" "3000" "-b" "::" ];
        entrypoint = "web-entrypoint.sh";
        publishPorts = [ "3000:3000" ];
        volumes = [
          "${volumes.dawarich-public.ref}:/var/app/public"
          "${volumes.dawarich-watched.ref}:/var/app/tmp/imports/watched"
          "${volumes.dawarich-storage.ref}:/var/app/storage"
          "${volumes.dawarich-db-data.ref}:/dawarich_db_data"
        ];
        environments = {
          RAILS_ENV = "development";
          REDIS_URL = "redis://dawarich-redis:6379/0";
          DATABASE_HOST = "dawarich-db";
          DATABASE_USERNAME = "postgres";
          DATABASE_PASSWORD = "password";
          DATABASE_NAME = "dawarich_development";
          QUEUE_DATABASE_PATH = "/dawarich_db_data/dawarich_development_queue.sqlite3";
          CACHE_DATABASE_PATH = "/dawarich_db_data/dawarich_development_cache.sqlite3";
          CABLE_DATABASE_PATH = "/dawarich_db_data/dawarich_development_cable.sqlite3";
          MIN_MINUTES_SPENT_IN_CITY = "60";
          APPLICATION_HOSTS = "localhost,nixnest";
          TIME_ZONE = "Europe/London";
          APPLICATION_PROTOCOL = "http";
          PROMETHEUS_EXPORTER_ENABLED = "false";
          PROMETHEUS_EXPORTER_HOST = "0.0.0.0";
          PROMETHEUS_EXPORTER_PORT = "9394";
          SELF_HOSTED = "true";
          STORE_GEODATA = "true";
        };
        # healthcheck = {
        #   test = [ "CMD-SHELL" "wget -qO - http://127.0.0.1:3000/api/v1/health | grep -q '\"status\"\\s*:\\s*\"ok\"'" ];
        #   interval = "10s";
        #   retries = 30;
        #   startPeriod = "30s";
        #   timeout = "10s";
        # };
        # resources = {
        #   cpus = "0.50";
        #   memory = "4G";
        # };
      };
      serviceConfig = {
        Restart = "on-failure";
      };
    };

    # Sidekiq service
    containers.dawarich-sidekiq = {
      containerConfig = {
        image = "freikin/dawarich:${version}";
        exec = [ "sidekiq" ];
        entrypoint = "sidekiq-entrypoint.sh";
        volumes = [
          "${volumes.dawarich-public.ref}:/var/app/public"
          "${volumes.dawarich-watched.ref}:/var/app/tmp/imports/watched"
          "${volumes.dawarich-storage.ref}:/var/app/storage"
        ];
        environments = {
          RAILS_ENV = "development";
          REDIS_URL = "redis://dawarich-redis:6379/0";
          DATABASE_HOST = "dawarich-db";
          DATABASE_USERNAME = "postgres";
          DATABASE_PASSWORD = "password";
          DATABASE_NAME = "dawarich_development";
          APPLICATION_HOSTS = "localhost,nixnest";
          BACKGROUND_PROCESSING_CONCURRENCY = "10";
          APPLICATION_PROTOCOL = "http";
          PROMETHEUS_EXPORTER_ENABLED = "false";
          PROMETHEUS_EXPORTER_HOST = "dawarich_app";
          PROMETHEUS_EXPORTER_PORT = "9394";
          SELF_HOSTED = "true";
          STORE_GEODATA = "true";
        };
        # healthcheck = {
        #   test = [ "CMD-SHELL" "bundle exec sidekiqmon processes | grep $${HOSTNAME}" ];
        #   interval = "10s";
        #   retries = 30;
        #   startPeriod = "30s";
        #   timeout = "10s";
        # };
        # resources = {
        #   cpus = "0.50";
        #   memory = "4G";
        # };
      };
      serviceConfig = {
        Restart = "on-failure";
      };
    };
  };
}
