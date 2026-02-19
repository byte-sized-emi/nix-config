{ config, ... }:
let
  settings = config.settings;
in
{
  my.services.homepage-dashboard = {
    enable = true;
    name = "Homepage Dashboard";
    description = "Central hub for all my services";
    port = config.services.homepage-dashboard.listenPort;
    external = {
      enable = true;
      domain = settings.home.domain;
    };
  };

  services.homepage-dashboard = {
    enable = true;
    allowedHosts = "${settings.home.domain}";
    services = [
      {
        "Internet services" = [
          {
            Linktree = {
              description = "Central hub for all my links";
              icon = "si-linktree";
              href = "https://${settings.domain}";
              siteMonitor = "https://${settings.domain}";
            };
          }
          {
            Forgejo = {
              description = "self-hosted git server";
              icon = "forgejo";
              href = "https://${settings.git.domain}";
              siteMonitor = "https://${settings.git.domain}";
            };
          }
          {
            Mealie = {
              description = "Service for keeping track of recipes";
              icon = "mealie";
              href = "https://${settings.meals.domain}";
              siteMonitor = "https://${settings.meals.domain}";
              # TODO: Add service widget here
              # https://gethomepage.dev/widgets/services/mealie/
            };
          }
          {
            Immich = {
              description = "Photo and video backup and management service";
              icon = "immich";
              href = "https://${settings.immich.domain}";
              siteMonitor = "https://${settings.immich.domain}";
              # TODO: Add service widget here
              # https://gethomepage.dev/widgets/services/immich/
            };
          }
          {
            Vaultwarden = {
              description = "Secrets management service";
              icon = "bitwarden";
              href = "https://${settings.secrets.domain}";
              siteMonitor = "https://${settings.secrets.domain}";
            };
          }
          {
            Kanidm = {
              description = "SSO for most services";
              icon = "kanidm";
              href = "https://${settings.sso.domain}";
              siteMonitor = "https://${settings.sso.domain}";
            };
          }
          # TODO: Home-assistant?
        ];
      }
      # TODO: Add infrastructure services here
      # https://gethomepage.dev/widgets/services/cloudflared/
      # TODO: Add intranet services here
    ];
  };
}
