{ config, ... }:
let
  stackPath = "/var/stacks/media";
  jellyfinPath = "${stackPath}/jellyfin";
  dataPath = "/data";
  port = 8096;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}             0770 root root"
    "d ${jellyfinPath}          0770 root root"
    "d ${jellyfinPath}/config   0770 root root"
    "d ${jellyfinPath}/cache    0770 root root"
    "d ${dataPath}/media/movies 0770 root root"
    "d ${dataPath}/media/tv     0770 root root"
    "d ${dataPath}/media/music  0770 root root"
    "d ${dataPath}/media/books  0770 root root"
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

  my.services.jellyfin = {
    enable = true;
    inherit port;
    description = "Jellyfin Media server";
    internal = {
      enable = true;
      domain = config.settings.media.service_domain;
    };
  };

  virtualisation.quadlet = {
    containers.jellyfin = {
      containerConfig = {
        image = "jellyfin/jellyfin:10.11.6.20260119-010354";
        publishPorts = [
          "127.0.0.1:${toString port}:${toString port}/tcp"
          "7359:7359/udp" # client discovery
        ];
        volumes = [
          "${jellyfinPath}/config:/config"
          "${jellyfinPath}/cache:/cache"
          "${dataPath}/media:/media"
        ];
        environments = {
          JELLYFIN_PublishedServerUrl = "https://${config.settings.media.service_domain}";
        };
      };
      serviceConfig = {
        Restart = "always";
      };
    };
  };

}
