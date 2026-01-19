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
      "immich/envFile".owner = "root";
      "kanidm/tlsChain".owner = users.kanidm.name;
      "kanidm/tlsKey".owner = users.kanidm.name;
      "kanidm/tailscaleOauthSecret".owner = users.kanidm.name;
      "kanidm/forgejoOauthSecret".owner = users.kanidm.name;
      "kanidm/mealieOauthSecret".owner = users.kanidm.name;
      "kanidm/immichOauthSecret".owner = users.kanidm.name;
      "kanidm/mealieOauthSecretEnv".owner = "root";
      "vaultwarden/env".owner = users.vaultwarden.name;
      "beeper_bridge_manager/config" = { };
    };
}
