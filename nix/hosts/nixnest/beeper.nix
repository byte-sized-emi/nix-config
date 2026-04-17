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
          image = "ghcr.io/beeper/bridge-manager:latest@sha256:26ecbacbafdfa7b0c0ec1411f5ecf9f26afe3741dad5d14f559db83c0f8ef62f";
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
