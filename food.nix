{ config, lib, settings, ... }:
let
  port = "9925";
  hostname = "meals.${settings.services.domain}";
in {
  services.caddy.virtualHosts."${hostname}" = {
    extraConfig = ''
      reverse_proxy localhost:${port}
    '';
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes;
  in {
    volumes = {
      mealie-data = {
        volumeConfig = { };
      };
    };

    containers.mealie = {
      containerConfig = {
        image = "hkotel/mealie:v3.3.1";
        publishPorts = [ "${port}:9000" ];
        environments = {
          PUID = "1000";
          PGID = "1000";
          TZ = "Europe/Berlin";
          BASE_URL = "https://${hostname}";
          ALLOW_PASSWORD_LOGIN = "true";
          ALLOW_SIGNUP = "false";
          DB_ENGINE = "sqlite";
          # Default Recipe Settings
          RECIPE_PUBLIC = "true";
          RECIPE_SHOW_NUTRITION = "true";
          RECIPE_SHOW_ASSETS = "true";
          RECIPE_LANDSCAPE_VIEW = "true";
          RECIPE_DISABLE_COMMENTS = "false";
          RECIPE_DISABLE_AMOUNT = "false";
          OIDC_AUTH_ENABLED = "true";
          OIDC_SIGNUP_ENABLED = "true";
          OIDC_CONFIGURATION_URL = "https://sso.byte-sized.fyi/oauth2/openid/mealie/.well-known/openid-configuration";
          OIDC_CLIENT_ID = "mealie";
          OIDC_PROVIDER_NAME = "kanidm";
          OIDC_USER_CLAIM = "preferred_username";
          OIDC_USER_GROUP = "mealie_users@sso.byte-sized.fyi";
          OIDC_ADMIN_GROUP = "mealie_users@sso.byte-sized.fyi";
          OIDC_AUTO_REDIRECT = "true"; # set ?direct=1 to disable
          OIDC_REMEMBER_ME = "true";
        };
        environmentFiles = [
          "/var/mealie/oauth_secret.env" # Sets OIDC_CLIENT_SECRET
        ];
        volumes = [
          "${volumes.mealie-data.ref}:/app/data"
        ];
      };
      serviceConfig = {
        Restart = "always";
      };
    };
  };
}
