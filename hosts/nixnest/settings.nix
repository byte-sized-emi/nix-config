{ lib, config, ... }:
with lib;
let
  cfg = config.settings;
in
{
  options.settings = {
    domain = mkOption {
      type = types.str;
      default = "byte-sized.fyi";
    };

    home.domain = mkOption {
      type = types.str;
      default = "home.${cfg.domain}";
    };

    sso.domain = mkOption {
      type = types.str;
      default = "sso.${cfg.domain}";
    };

    meals.domain = mkOption {
      type = types.str;
      default = "meals.${cfg.domain}";
    };

    meals.service_domain = mkOption {
      type = types.str;
      default = "meals.${cfg.services.domain}";
    };

    services.domain = mkOption {
      type = types.str;
      default = "service.${cfg.domain}";
    };

    git.domain = mkOption {
      type = types.str;
      default = "git.${cfg.domain}";
    };

    immich.domain = mkOption {
      type = types.str;
      default = "images.${cfg.domain}";
    };

    secrets.domain = mkOption {
      type = types.str;
      default = "secrets.${cfg.domain}";
    };

    dawarich.enable = mkOption {
      type = types.bool;
      default = false;
    };

    ingress_tunnel = mkOption {
      type = types.str;
      default = "a7cff2a8-b287-4edc-94fd-35527c3c3858";
    };

    backup = {
      interval = mkOption {
        type = types.str;
        default = "Mon,Fri 02:00";
      };

      prepare = {
        interval = mkOption {
          type = types.str;
          default = "Mon,Fri 01:20";
        };

        interval_cron = mkOption {
          type = types.str;
          default = "20 1 * * 1,5";
        };
      };
    };
  };
}
