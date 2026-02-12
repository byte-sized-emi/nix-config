{ config, ... }:
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
          image = "ghcr.io/beeper/bridge-manager:8ff78f238554b359e24eb196649eaea0179a700b";
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
{
  virtualisation.quadlet = bridge "sh-discord";
}
