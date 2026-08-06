{
  config,
  ...
}:
let
  stackPath = "/var/stacks/home-automation";
  homeAssistantPath = "${stackPath}/home-assistant";
  openthreadPath = "${stackPath}/openthread";
  matterPath = "${stackPath}/matter";
  esphomePath = "${stackPath}/esphome";
  threadInfraIfName = "enp2s0";
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

  my.services.esphome = {
    enable = true;
    name = "ESPHome";
    port = 6052;
    internal.enable = true;
  };

  networking.firewall.allowedTCPPorts = [ port ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.${threadInfraIfName}.accept_ra" = 2;
    "net.ipv6.conf.${threadInfraIfName}.accept_ra_rt_info_max_plen" = 64;
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath}              0770 root root"
    "d ${homeAssistantPath}      0770 root root"
    "d ${openthreadPath}         0770 root root"
    "d ${matterPath}             0770 root root"
    "d ${esphomePath}            0770 root root"
    "d ${esphomePath}/config     0770 root root"
    "d ${esphomePath}/platformio 0770 root root"
  ];

  environment.etc."dev/openthread-radio-USB-JTAG".source =
    "/dev/serial/by-id/usb-Espressif_USB_JTAG_serial_debug_unit_AC:EB:E6:C1:52:2C-if00";

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
          exposePorts = [ (toString port) ];
          addCapabilities = [ "CAP_NET_RAW" ];
          volumes = [
            "${homeAssistantPath}/config:/config"
            "/etc/stacks/home-assistant/config/configuration.yaml:/config/configuration.yaml:ro"
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

      containers.openthread = {
        containerConfig = {
          image = "docker.io/openthread/border-router:latest@sha256:279b34593ab1632b17b67388361a42a6a9f940ac05a028896a944562cd3ba360";
          environments = {
            TZ = "Europe/Berlin";
            OT_RCP_DEVICE = "spinel+hdlc+uart:///dev/ttyACM0?uart-baudrate=460800";
            OT_INFRA_IF = threadInfraIfName;
            OT_THREAD_IF = "wpan0";
            OT_LOG_LEVEL = "4";
            OT_REST_PORT = "8981";
            OT_REST_LISTEN_PORT = "8981";
            OT_FLOW_CONTROL = "0";
            FLOW_CONTROL = "0";
          };
          devices = [
            "/etc/dev/openthread-radio-USB-JTAG:/dev/ttyACM0"
            "/dev/net/tun"
          ];
          exposePorts = [
            "8981"
          ];
          addCapabilities = [
            "NET_ADMIN"
            "NET_RAW"
          ];
          volumes = [
            "${openthreadPath}:/data"
          ];
          networks = [
            "host"
          ];
        };
      };

      containers.matter = {
        containerConfig = {
          image = "ghcr.io/matter-js/python-matter-server:8.1.2";
          environments = {
            TZ = "Europe/Berlin";
          };
          volumes = [
            "${matterPath}:/data"
          ];
          networks = [
            "host"
          ];
        };
      };
      containers.esphome = {
        containerConfig = {
          image = "ghcr.io/esphome/esphome:2026.7.2";
          environments = {
            TZ = "Europe/Berlin";
          };
          exposePorts = [
            "6052"
          ];
          addCapabilities = [
            "CAP_NET_RAW"
          ];
          volumes = [
            "${esphomePath}/config:/config"
            "${esphomePath}/platformio:/root/.platformio"
          ];
          networks = [
            "host"
          ];
        };
      };
    };
}
