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
                  image = "ghcr.io/beeper/bridge-manager:latest@sha256:cb8f96048ef38c7de95358cdab5ff40befd8c4ecb6b357a1be9e1003302f7c54";
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
