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
          image = "ghcr.io/beeper/bridge-manager:latest@sha256:b8b34254f6a0d99ddc3ac2e4952443dadb3c0fd82307a9a4e05898ee9b4adc7f";
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
