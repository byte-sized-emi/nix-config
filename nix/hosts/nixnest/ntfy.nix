{ config, ... }:
{
  my.services.ntfy = {
    enable = true;
    port = 2586;
    description = "ntfy notification server";
    internal = {
      enable = true;
      domain = config.settings.ntfy.service_domain;
    };
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      listen-http = ":2586";
      base-url = "https://${config.settings.ntfy.service_domain}";
      behind-proxy = true;
    };
  };
}
