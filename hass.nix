{ config, ...}: let
  homeAssistantPath = "/etc/stacks/home-assistant";
in {
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes;
  in {
    containers.home-assistant = {
      containerConfig = {
        image = "ghcr.io/home-assistant/home-assistant:2025.4.4";
        environments.TZ = "Europe/Berlin";
        exposePorts = [ "8123" ];
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
        # FIXME: Switch to expose?
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
        # FIXME: Switch to expose?
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
