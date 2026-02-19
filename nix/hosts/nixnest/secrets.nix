{ config, ... }:
{
  sops.secrets =
    let
      inherit (config.users) users groups;
    in
    {
      "cloudflared/tunnel".owner = users.cloudflared.name;
      "borg/backupKey" = {
        owner = users.borg.name;
        group = groups.borg.name;
      };
      "caddy/secretsEnv".owner = users.caddy.name;
      "forgejo/actionsRunnerToken" = {
        owner = users.forgejo.name;
        group = groups.forgejo.name;
      };
      "immich/dbPassword".owner = "root";
      "kanidm/tlsChain".owner = users.kanidm.name;
      "kanidm/tlsKey".owner = users.kanidm.name;
      "kanidm/tailscaleOauthSecret".owner = users.kanidm.name;
      "kanidm/forgejoOauthSecret".owner = users.kanidm.name;
      "kanidm/mealieOauthSecret".owner = users.kanidm.name;
      "kanidm/immichOauthSecret".owner = users.kanidm.name;
      "kanidm/mealieOauthSecretEnv".owner = "root";
      "vaultwarden/env".owner = users.vaultwarden.name;
      "beeper_bridge_manager/config" = { };
      "umami/dbPassword" = { };
      "umami/appSecret" = { };
    };

  sops.templates = {
    "immich/envFile" = {
      content = ''
        DB_PASSWORD=${config.sops.placeholder."immich/dbPassword"}
        DB_USERNAME=postgres
        DB_DATABASE_NAME=immich
      '';
      owner = "root";
    };
    "umami/postgresEnvFile" = {
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder."umami/dbPassword"}
      '';
    };
    "umami/dbUrl".content = "postgresql://postgres:${
      config.sops.placeholder."umami/dbPassword"
    }@localhost:5444/umami";
  };
}
