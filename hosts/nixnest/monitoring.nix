{ config, settings, ... }:
{
  # monitoring uses the 9000 range of ports
  # adapted from https://oblivion.keyruu.de/Homelab/Monitoring
  services.cadvisor = {
    enable = true;
    port = 9091;
    extraOptions = [ "--docker_only=false" ];
  };

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    checkConfig = true;
    # TODO: Backups
    # can be created with curl -XPOST http://localhost:9090/api/v1/admin/tsdb/snapshot
    # will then be located in /var/lib/prometheus2/data/snapshots/
    # Make sure to delete old snapshots - even though they are hardlinked,
    # they will take up space.
    extraFlags = [ "--web.enable-admin-api" ];

    exporters = {
      node = {
        enable = true;
        port = 9092;
        enabledCollectors = [ "systemd" ];
      };
    };

    scrapeConfigs = [
      {
        job_name = "node_exporter";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
            ];
          }
        ];
      }
      {
        job_name = "cadvisor";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.cadvisor.port}"
            ];
          }
        ];
      }
    ];
  };

  # this puts the folder dashboards on the host system at /etc/grafana/dashboards
  environment.etc."grafana/dashboards" = {
    source = ./dashboards;
    user = "grafana";
    group = "grafana";
  };

  # TODO: auth
  # maybe from this?
  # https://github.com/oddlama/nix-config/blob/main/hosts/sire/guests/grafana.nix#L183
  # https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/generic-oauth/#configure-generic-oauth-authentication-client-using-the-grafana-configuration-file
  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 9093;
      };

      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
      };
    };

    provision = {
      enable = true;
      dashboards.settings.providers = [
        {
          # this tells grafana to look at the path for dashboards
          options.path = "/etc/grafana/dashboards";
        }
      ];
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        }
      ];
    };
  };

  services.caddy.virtualHosts."grafana.${settings.services.domain}" = {
    extraConfig = ''
      reverse_proxy localhost:${toString config.services.grafana.settings.server.http_port}
    '';
  };
}
