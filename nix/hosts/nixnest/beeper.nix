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
              image = "ghcr.io/beeper/bridge-manager:latest@sha256:ecfe4bd67ed53b3649f57850c67c55dd12584c8be0500a910a67d4892d413338";
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
