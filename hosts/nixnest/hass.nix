{
  config,
  settings,
  ...
}:
let
  homeAssistantPath = "/etc/stacks/home-assistant";
  port = 8123;
in
{
  services.caddy.virtualHosts."homeassistant.${settings.services.domain}" = {
    extraConfig = ''
      reverse_proxy localhost:${toString port}
    '';
  };

  networking.firewall.allowedTCPPorts = [ port ];

  environment.etc."stacks/home-assistant/config/configuration.yaml".text = # yaml
    ''
      # Loads default set of integrations. Do not remove.
      default_config:

      automation: !include automations.yaml
      script: !include scripts.yaml
      scene: !include scenes.yaml

      http:
        use_x_forwarded_for: true
        trusted_proxies:
          - 127.0.0.1
          - ::1
          - 100.64.0.0/10
    '';

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      containers.home-assistant = {
        containerConfig = {
          image = "ghcr.io/home-assistant/home-assistant:2025.4.4";
          environments.TZ = "Europe/Berlin";
          exposePorts = [ "${toString port}" ];
          addCapabilities = [ "CAP_NET_RAW" ];
          volumes = [
            "${homeAssistantPath}/config:/config"
            "${homeAssistantPath}/config/configuration.yaml:/config/configuration.yaml:ro"
            "/run/dbus:/run/dbus:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
          networks = [ "host" ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };

      volumes.whisper-data = {
        volumeConfig = {
          type = "bind";
          device = "/tmp/whisper-data";
        };
      };

      volumes.piper-data = {
        volumeConfig = {
          type = "bind";
          device = "/tmp/piper-data";
        };
      };

      containers.whisper = {
        # volume
        containerConfig = {
          image = "rhasspy/wyoming-whisper:2.4.0";
          environments.TZ = "Europe/Berlin";
          publishPorts = [ "127.0.0.1:10300:10300" ];
          exec = "--model small-int8 --language de";
          volumes = [
            "${volumes.whisper-data.ref}:/data"
          ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };

      containers.piper = {
        containerConfig = {
          image = "rhasspy/wyoming-piper:1.5.0";
          environments.TZ = "Europe/Berlin";
          publishPorts = [ "127.0.0.1:10200:10200" ];
          exec = "--voice de_DE-ramona-low";
          volumes = [
            "${volumes.piper-data.ref}:/data"
          ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };
    };
}
