{ config, ... }:
{
  my.services.umami = {
    enable = false; # TODO: Change me
    name = "Umami";
    port = config.services.umami.settings.PORT;
    description = "Self-hosted web analytics service";
    external = {
      enable = false;
      domain = "analytics.${config.settings.services.domain}";
    };
  };

  services.umami = {
    enable = false; # TODO: Change me
    settings = {
      PORT = 3243;
    };
  };
}
