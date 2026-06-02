{
  config,
  ...
}:
let
  homeAssistantPath = "/etc/stacks/home-assistant";
  threadInfraIfName = "eth0";
  port = 8123;
in
{
  my.services.homeAssistant = {
    enable = true;
    name = "Home Assistant";
    inherit port;
    description = "Home automation platform";
    internal = {
      enable = true;
      domain = "homeassistant.${config.settings.services.domain}";
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.${threadInfraIfName}.accept_ra" = 2;
    "net.ipv6.conf.${threadInfraIfName}.accept_ra_rt_info_max_plen" = 64;
  };

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
    # let
    #   inherit (config.virtualisation.quadlet) volumes;
    # in
    {
      containers.home-assistant = {
        containerConfig = {
          image = "ghcr.io/home-assistant/home-assistant:2026.5.4";
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

      # volumes.whisper-data = {
      #   volumeConfig = {
      #     type = "bind";
      #     device = "/tmp/whisper-data";
      #   };
      # };

      # volumes.piper-data = {
      #   volumeConfig = {
      #     type = "bind";
      #     device = "/tmp/piper-data";
      #   };
      # };

      # containers.whisper = {
      #   # volume
      #   containerConfig = {
      #     image = "rhasspy/wyoming-whisper:3.1.0";
      #     environments.TZ = "Europe/Berlin";
      #     publishPorts = [ "127.0.0.1:10300:10300" ];
      #     exec = "--model small-int8 --language de";
      #     volumes = [
      #       "${volumes.whisper-data.ref}:/data"
      #     ];
      #   };
      #   serviceConfig = {
      #     Restart = "always";
      #   };
      # };

      # containers.piper = {
      #   containerConfig = {
      #     image = "rhasspy/wyoming-piper:2.2.2";
      #     environments.TZ = "Europe/Berlin";
      #     publishPorts = [ "127.0.0.1:10200:10200" ];
      #     exec = "--voice de_DE-ramona-low";
      #     volumes = [
      #       "${volumes.piper-data.ref}:/data"
      #     ];
      #   };
      #   serviceConfig = {
      #     Restart = "always";
      #   };
      # };

      # containers.openthread = {
      #   containerConfig = {
      #     image = "docker.io/openthread/border-router:latest@sha256:fd123415d97ac5e6ef5cb8e48632397edca40263afb5dbd1651685662b550b65";
      #     environments = {
      #       TZ = "Europe/Berlin";
      #       OT_RCP_DEVICE = "spinel+hdlc+uart:///dev/ttyACM0?uart-baudrate=460800";
      #       OT_INFRA_IF = threadInfraIfName;
      #       OT_THREAD_IF = "wpan0";
      #       OT_LOG_LEVEL = "7";
      #       OT_REST_PORT = "8981";
      #       OT_REST_LISTEN_PORT = "8981";
      #       OT_FLOW_CONTROL = "0";
      #       FLOW_CONTROL = "0";
      #     };
      #     devices = [
      #       "/dev/serial/by-id/usb-Espressif_USB_JTAG_serial_debug_unit_AC:EB:E6:C2:85:68-if00:/dev/ttyACM0"
      #       "/dev/net/tun"
      #     ];
      #     exposePorts = [
      #       "8981"
      #     ];
      #     addCapabilities = [
      #       "NET_ADMIN"
      #       "NET_RAW"
      #     ];
      #     volumes = [
      #       "${homeAssistantPath}/data:/data"
      #     ];
      #     networks = [
      #       "host"
      #     ];
      #   };
      # };

      containers.otbr = {
        containerConfig = {
          image = "ghcr.io/ownbee/hass-otbr-docker";
          environments = {
            DEVICE = "/dev/ttyACM0";
            FLOW_CONTROL = "1";
            FIREWALL = "1";
            NAT64 = "1";
            BAUDRATE = "460800";
            OTBR_REST_PORT = "8081";
            OTBR_WEB_PORT = "7586";
            AUTOFLASH_FIRMWARE = "0";
            BACKBONE_IF = "eth0";
          };
          devices = [
            "/dev/ttyACM0:/dev/ttyACM0"
          ];
          volumes = [
            "${homeAssistantPath}/data:/var/lib/thread"
          ];
          networks = [ "host" ];
          extraOptions = [ "--privileged" ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };
    };
}
