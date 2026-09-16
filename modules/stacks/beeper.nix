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
                  image = "ghcr.io/beeper/bridge-manager:latest@sha256:5af5ee23ec5b679dac6c1be12fc1d73b33ac6842f7ad82de62954d8b5a59b536";
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
