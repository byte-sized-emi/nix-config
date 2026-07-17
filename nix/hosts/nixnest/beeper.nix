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
              image = "ghcr.io/beeper/bridge-manager:latest@sha256:ca3935d281a667f42ddbb79cd2dc73b3e41369e34073ecd901f09b866dd8eee0";
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
