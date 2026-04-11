{ config, ... }:
let
  uploadLocation = "/var/immich/upload_location";
  # renovate: datasource=docker depName=ghcr.io/immich-app/immich-server
  immichVersion = "v2.7.4";
  stackPath = "/etc/stacks/immich";
  port = 2283;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/pgdata 0770 999 999"
    "d ${stackPath}/model-cache 0770 root root"
    "d /var/immich/upload_location 0770 root root"
  ];

  my.services.immich = {
    enable = true;
    name = "Immich";
    inherit port;
    external = {
      enable = true;
      domain = config.settings.immich.domain;
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.immich.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=immich" ];
      };

      containers = {
        immich-server = {
          containerConfig = {
            image = "ghcr.io/immich-app/immich-server:${immichVersion}";
            publishPorts = [
              "${toString port}:${toString port}"
            ];
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "${uploadLocation}:/data"
            ];
            environmentFiles = [ config.sops.templates."immich/envFile".path ];
            networks = [ networks.immich.ref ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [
              "immich-redis.service"
              "immich-database.service"
            ];
            Requires = [
              "immich-redis.service"
              "immich-database.service"
            ];
          };
        };

        immich-machine-learning = {
          containerConfig = {
            image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}";
            volumes = [
              "${stackPath}/model-cache:/cache"
            ];
            environmentFiles = [ config.sops.templates."immich/envFile".path ];
            networks = [ networks.immich.ref ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = "immich-server.service";
            Requires = "immich-server.service";
          };
        };

        immich-redis = {
          containerConfig = {
            image = "docker.io/valkey/valkey:9.1@sha256:50b70cdef934d4b6a4aced5579ac3e3a4a34f36a045851bb7a3306ead1931d27";
            healthCmd = "redis-cli ping || exit 1";
            networks = [ networks.immich.ref ];
            networkAliases = [ "redis" ];
            notify = "healthy";
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        # this is backed up in ./backups.nix
        immich-database = {
          containerConfig = {
            image = "ghcr.io/immich-app/postgres:18-vectorchord0.5.3-pgvector0.8.1";
            environmentFiles = [ config.sops.templates."immich/envFile".path ];
            environments = {
              POSTGRES_INITDB_ARGS = "--data-checksums";
            };
            securityLabelDisable = true;
            volumes = [
              "${stackPath}/pgdata:/var/lib/postgresql/:z"
            ];
            networks = [ networks.immich.ref ];
            networkAliases = [ "database" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };
      };
    };
}
