{
  config,
  ...
}:
let
  port = 9925;
in
{
  sops.secrets."kanidm/mealieOauthSecret".owner = config.users.users.kanidm.name;
  sops.secrets."kanidm/mealieOauthSecretEnv".owner = "root";

  my.services.mealie = {
    enable = true;
    name = "Mealie";
    inherit port;
    description = "Recipe management and meal planning application";
    internal = {
      enable = true;
      domain = config.settings.meals.service_domain;
    };
    external = {
      enable = true;
      domain = config.settings.meals.domain;
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
    in
    {
      volumes = {
        mealie-data = {
          volumeConfig = { };
        };
      };

      containers.mealie = {
        containerConfig = {
          image = "hkotel/mealie:v3.16.0@sha256:74496aed2c5055e3b7b6c4e1bb9b4f16b1f566601582b258a10bae851f19ac24";
          publishPorts = [ "127.0.0.1:${toString port}:9000" ];
          environments = {
            PUID = "1000";
            PGID = "1000";
            TZ = "Europe/Berlin";
            BASE_URL = "https://${config.settings.meals.domain}";
            ALLOW_PASSWORD_LOGIN = "true";
            ALLOW_SIGNUP = "false";
            DB_ENGINE = "sqlite";
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
            OIDC_ADMIN_GROUP = "mealie_admins@sso.byte-sized.fyi";
            OIDC_AUTO_REDIRECT = "true"; # set ?direct=1 to disable
            OIDC_REMEMBER_ME = "true";
          };
          environmentFiles = [
            config.sops.secrets."kanidm/mealieOauthSecretEnv".path # Sets OIDC_CLIENT_SECRET
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
