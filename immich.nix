{ config, settings, ... }:
let
  UPLOAD_LOCATION = "/var/immich/upload_location";
  IMMICH_VERSION = "v2.2.3";
  stackPath = "/etc/stacks/immich";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/pgdata 0770 999 999"
    "d ${stackPath}/model-cache 0770 root root"
    "d /var/immich/upload_location 0770 root root"
  ];

  services.cloudflared.tunnels.${settings.ingress_tunnel}.ingress = {
    ${settings.immich.domain} = "http://localhost:2283";
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
            image = "ghcr.io/immich-app/immich-server:${IMMICH_VERSION}";
            publishPorts = [
              "127.0.0.1:2283:2283"
            ];
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "${UPLOAD_LOCATION}:/data"
            ];
            environmentFiles = [ config.sops.secrets."immich/envFile".path ];
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
            image = "ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION}";
            volumes = [
              "${stackPath}/model-cache:/cache"
            ];
            environmentFiles = [ config.sops.secrets."immich/envFile".path ];
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
            image = "docker.io/library/redis:6.2-alpine@sha256:c5a607fb6e1bb15d32bbcf14db22787d19e428d59e31a5da67511b49bb0f1ccc";
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
            image = "ghcr.io/immich-app/postgres:14-vectorchord0.3.0-pgvectors0.2.0";
            environmentFiles = [ config.sops.secrets."immich/envFile".path ];
            environments = {
              POSTGRES_INITDB_ARGS = "--data-checksums";
            };
            securityLabelDisable = true;
            volumes = [
              "${stackPath}/pgdata:/var/lib/postgresql/data:z"
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
