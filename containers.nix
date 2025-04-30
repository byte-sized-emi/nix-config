{...}: let
  homeAssistantPath = "/etc/stacks/home-assistant";
in {
  virtualisation.containers.enable = true;

  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];

  environment.etc."stacks/home-assistant/config/configuration.yaml".text = /* yaml */ ''
    # Loads default set of integrations. Do not remove.
    default_config:

    automation: !include automations.yaml
    script: !include scripts.yaml
    scene: !include scenes.yaml
  '';

  virtualisation.quadlet.containers.home-assistant = {
    containerConfig = {
      image = "ghcr.io/home-assistant/home-assistant:2025.4.4";
      environments = {
        TZ = "Europe/Berlin";
      };
      exposePorts = [
        "8123"
      ];
      addCapabilities = [
        "CAP_NET_RAW"
      ];
      volumes = [
        "${homeAssistantPath}/config:/config"
        "${homeAssistantPath}/config/configuration.yaml:/config/configuration.yaml:ro"
        "/run/dbus:/run/dbus:ro"
        "/etc/localtime:/etc/localtime:ro"
      ];
      networks = [
        "host"
      ];
      labels = [
        "wud.tag.include=^\d+\.\d+\.\d+$"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
