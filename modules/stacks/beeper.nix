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
                  image = "ghcr.io/beeper/bridge-manager:latest@sha256:ca0fc1211a982eb90e836fbf0ba0654e07ccc151a80320ac314b5bc80828c50a";
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
