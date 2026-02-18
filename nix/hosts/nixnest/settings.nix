{ lib, ... }:
with lib;
{
  options.settings = {
    domain = mkOption {
      type = types.str;
    };

    home.domain = mkOption {
      type = types.str;
    };

    sso.domain = mkOption {
      type = types.str;
    };

    meals.domain = mkOption {
      type = types.str;
    };

    meals.service_domain = mkOption {
      type = types.str;
    };

    services.domain = mkOption {
      type = types.str;
    };

    git.domain = mkOption {
      type = types.str;
    };

    immich.domain = mkOption {
      type = types.str;
    };

    secrets.domain = mkOption {
      type = types.str;
    };

    cache.service_domain = mkOption {
      type = types.str;
    };

    dawarich.enable = mkOption {
      type = types.bool;
    };

    ingress_tunnel = mkOption {
      type = types.str;
    };

    backup = {
      interval = mkOption {
        type = types.str;
      };

      prepare = {
        interval = mkOption {
          type = types.str;
        };

        interval_cron = mkOption {
          type = types.str;
        };
      };
    };
  };

  config.settings = rec {
    domain = "byte-sized.fyi";
    home.domain = "home.${domain}";
    sso.domain = "sso.${domain}";
    meals.domain = "meals.${domain}";
    git.domain = "git.${domain}";
    immich.domain = "images.${domain}";
    secrets.domain = "secrets.${domain}";
    services.domain = "service.${domain}";
    meals.service_domain = "meals.${services.domain}";
    cache.service_domain = "cache.${services.domain}";
    dawarich.enable = true;
    ingress_tunnel = "a7cff2a8-b287-4edc-94fd-35527c3c3858";
    backup.interval = "Mon,Fri 02:00";
    backup.prepare.interval = "Mon,Fri 01:20";
    backup.prepare.interval_cron = "20 1 * * 1,5";
  };
}
