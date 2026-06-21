{ config, ... }:
{
  sops.secrets."beeper_bridge_manager/config" = { };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
      bridge =
        name:
        let
          volumeName = "beeper-${name}-data";
          volumeRef = volumes.${volumeName}.ref;
          configPath = config.sops.secrets."beeper_bridge_manager/config".path;
        in
        {
          volumes.${volumeName}.volumeConfig = { };
          containers."beeper-${name}" = {
            containerConfig = {
              image = "ghcr.io/beeper/bridge-manager:latest@sha256:7e66e447a606c65a02131c7736b4287d86283fd9f7b0640856044c972834999a";
              environments = {
                BRIDGE_NAME = name;
              };
              volumes = [
                "${volumeRef}:/data"
                "${configPath}:/tmp/bbctl.json:ro"
              ];
              # user = "1000";
              # group = "1000";
            };
            serviceConfig = {
              Restart = "always";
              RestartSec = "2s";
            };
          };
        };
    in
    bridge "sh-discord";
}
