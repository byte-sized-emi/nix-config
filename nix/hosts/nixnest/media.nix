{
  config,
  lib,
  ...
}:
let
  stackPath = "/var/stacks/media";
  jellyfinPath = "${stackPath}/jellyfin";
  sonarrPath = "${stackPath}/sonarr";
  radarrPath = "${stackPath}/radarr";
  prowlarrPath = "${stackPath}/prowlarr";
  qbittorrentPath = "${stackPath}/qbittorrent";
  gluetunPath = "${stackPath}/gluetun";
  quiPath = "${stackPath}/qui";
  dataPath = "/data";
  jellyfinPort = 8096;
  qbittorrentPort = 8097;
  sonarrPort = 8989;
  radarrPort = 7878;
  prowlarrPort = 9696;
  flareSolverrPort = 8191;
  quiPort = 7476;
  quiMetricsPort = "9074";
  inherit (config.users.users.media) uid;
  inherit (config.users.groups.media) gid;
in
{
  sops.secrets."openvpn/client_key" = {
    format = "binary";
    sopsFile = ../../secrets/openvpn_client.key;
  };
  sops.secrets."openvpn/client_cert" = {
    format = "binary";
    sopsFile = ../../secrets/openvpn_client_cert.crt;
  };
  sops.secrets.gluetunEnv = { };

  users.users.media = {
    uid = 311;
    group = "media";
  };

  users.groups.media = {
    gid = 311;
    members = [
      "media"
      "emilia"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath}                 0770 media media"
    "d ${sonarrPath}                0770 media media"
    "d ${radarrPath}                0770 media media"
    "d ${prowlarrPath}              0770 media media"
    "d ${qbittorrentPath}           0770 media media"
    "d ${gluetunPath}               0770 media media"
    "d ${quiPath}                   0770 media media"
    "d ${jellyfinPath}/config       0770 media media"
    "d ${jellyfinPath}/cache        0770 media media"

    # dataPath is now mounted, which makes this scary
    # - see nix/hosts/nixnest/hardware-configuration.nix for the mount
    # "d ${dataPath}/torrents/books   0775 media media"
    # "d ${dataPath}/torrents/movies  0775 media media"
    # "d ${dataPath}/torrents/music   0775 media media"
    # "d ${dataPath}/torrents/tv      0775 media media"
    # "d ${dataPath}/media/books      0775 media media"
    # "d ${dataPath}/media/movies     0775 media media"
    # "d ${dataPath}/media/music      0775 media media"
    # "d ${dataPath}/media/tv         0775 media media"
  ];

  # TRaSH guides recommended folder structure:
  # /data
  # ├── torrents
  # │   ├── books
  # │   ├── movies
  # │   ├── music
  # │   └── tv
  # ├── usenet
  # │   ├── incomplete
  # │   └── complete
  # │       ├── books
  # │       ├── movies
  # │       ├── music
  # │       └── tv
  # └── media
  #     ├── books
  #     ├── movies
  #     ├── music
  #     └── tv

  my.services = {
    jellyfin = {
      enable = true;
      port = jellyfinPort;
      description = "Jellyfin Media server";
      internal = {
        enable = true;
        domain = config.settings.media.service_domain;
      };
    };
    qbittorrent = {
      enable = true;
      port = qbittorrentPort;
      internal = {
        enable = true;
        domain = "torrent.${config.settings.services.domain}";
      };
    };
    qui = {
      enable = true;
      port = quiPort;
      internal.enable = true;
    };
    sonarr = {
      enable = true;
      port = sonarrPort;
      internal.enable = true;
    };
    radarr = {
      enable = true;
      port = radarrPort;
      internal.enable = true;
    };
    prowlarr = {
      enable = true;
      port = prowlarrPort;
      internal.enable = true;
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "qui";
      static_configs = [
        {
          targets = [
            "localhost:${quiMetricsPort}"
          ];
        }
      ];
      metrics_path = "/metrics";
      scrape_interval = "60s";
    }
  ];

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.media.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=media" ];
      };

      containers.jellyfin = {
        containerConfig = {
          image = "jellyfin/jellyfin:10.11.6.20260119-010354";
          publishPorts = [
            "127.0.0.1:${toString jellyfinPort}:${toString jellyfinPort}/tcp"
            "7359:7359/udp" # client discovery
          ];
          volumes = [
            "${jellyfinPath}/config:/config"
            "${jellyfinPath}/cache:/cache"
            "${dataPath}/media:/media"
          ];
          devices = [ "/dev/dri/renderD128:/dev/dri/renderD128" ];
          addGroups = [
            (toString (lib.defaultTo 303 config.users.groups.render.gid))
          ];
          environments = {
            JELLYFIN_PublishedServerUrl = "https://${config.settings.media.service_domain}";
          };
          networks = [ networks.media.ref ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };

      containers.sonarr = {
        containerConfig = {
          image = "lscr.io/linuxserver/sonarr:4.0.16.2944-ls304";
          volumes = [
            "${sonarrPath}:/config"
            "${dataPath}:/data"
          ];
          publishPorts = [
            "127.0.0.1:${toString sonarrPort}:${toString sonarrPort}/tcp"
          ];
          environments = {
            PUID = toString uid;
            PGID = toString gid;
          };
          networks = [ networks.media.ref ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };

      containers.radarr = {
        containerConfig = {
          image = "lscr.io/linuxserver/radarr:6.0.4.10291-ls295";
          volumes = [
            "${radarrPath}:/config"
            "${dataPath}:/data"
          ];
          publishPorts = [
            "127.0.0.1:${toString radarrPort}:${toString radarrPort}/tcp"
          ];
          environments = {
            PUID = toString uid;
            PGID = toString gid;
          };
          networks = [ networks.media.ref ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };

      containers.prowlarr = {
        containerConfig = {
          image = "lscr.io/linuxserver/prowlarr:2.3.0.5236-ls139";
          volumes = [
            "${prowlarrPath}:/config"
          ];
          environments = {
            PUID = toString uid;
            PGID = toString gid;
          };
          publishPorts = [
            "127.0.0.1:${toString prowlarrPort}:${toString prowlarrPort}/tcp"
          ];
          networks = [ networks.media.ref ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };

      containers.flaresolverr = {
        containerConfig = {
          image = "ghcr.io/flaresolverr/flaresolverr:v3.4.6";
          environments = {
            LOG_LEVEL = "info";
          };
          publishPorts = [
            "127.0.0.1:${toString flareSolverrPort}:${toString flareSolverrPort}/tcp"
          ];
          networks = [ networks.media.ref ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };

      containers.qui = {
        containerConfig = {
          image = "ghcr.io/autobrr/qui:v1.19.0@sha256:36e068e1f1cae0d055295701934137a27e570c37b4e931fe284b6389fe8fdcbc";
          user = "${toString uid}:${toString gid}";
          publishPorts = [
            "127.0.0.1:${toString quiPort}:${toString quiPort}/tcp"
            "127.0.0.1:${quiMetricsPort}:${quiMetricsPort}/tcp"
          ];
          volumes = [
            "${quiPath}:/config"
            "${dataPath}/torrents:/data/torrents"
          ];
          environments = {
            QUI__PORT = toString quiPort;
            QUI__LOG_LEVEL = "info";
            QUI__METRICS_ENABLED = "true";
            QUI__METRICS_HOST = "0.0.0.0";
            QUI__METRICS_PORT = quiMetricsPort;
          };
          networks = [ networks.media.ref ];
        };
      };

      containers.qbittorrent = {
        containerConfig = {
          image = "lscr.io/linuxserver/qbittorrent:5.1.4-r2-ls448";
          volumes = [
            "${qbittorrentPath}:/config"
            "${dataPath}/torrents:/data/torrents"
          ];
          environments = {
            PUID = toString uid;
            PGID = toString gid;
            TZ = "Europe/Berlin";
            WEBUI_PORT = toString qbittorrentPort;
            TORRENTING_PORT = "41589";
          };
          networks = [ "gluetun.container" ];
          memory = "2g";
        };
      };

      containers.gluetun = {
        containerConfig = {
          image = "ghcr.io/qdm12/gluetun:v3.41.1@sha256:1a5bf4b4820a879cdf8d93d7ef0d2d963af56670c9ebff8981860b6804ebc8ab";
          addCapabilities = [
            "NET_ADMIN"
            "NET_RAW" # for ICMP listening
          ];
          devices = [ "/dev/net/tun:/dev/net/tun" ];
          volumes = [
            "${gluetunPath}:/gluetun"
            "${config.sops.secrets."openvpn/client_key".path}:/gluetun/client.key"
            "${config.sops.secrets."openvpn/client_cert".path}:/gluetun/client.crt"
          ];
          publishPorts = [
            "127.0.0.1:${toString qbittorrentPort}:${toString qbittorrentPort}"
          ];
          networks = [ networks.media.ref ];
          # TODO: remove this once IPv6 works again
          sysctl = {
            "net.ipv6.conf.all.disable_ipv6" = "1";
            "net.ipv6.conf.default.disable_ipv6" = "1";
          };
          environmentFiles = [ config.sops.secrets.gluetunEnv.path ];
          environments = {
            TZ = "Europe/Berlin";
            UPDATER_PERIOD = "24h";
            VPN_TYPE = "openvpn";
            OPENVPN_PROTOCOL = "tcp";
            SERVER_REGIONS = "Europe";
            FIREWALL_VPN_INPUT_PORTS = "41589";
            BORINGPOLL_GLUETUNCOM = "on";
          };
        };
      };
    };
}
