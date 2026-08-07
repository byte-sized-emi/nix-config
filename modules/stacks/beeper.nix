{
  stacks.beeper.nixos =
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
                  image = "ghcr.io/beeper/bridge-manager:latest@sha256:276af44ca3285347011d82c3f3f7f7616a39f7a40c2962a9fe73f0fc4a9d2922";
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
    };
}
