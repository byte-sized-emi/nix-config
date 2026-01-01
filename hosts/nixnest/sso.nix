{
  pkgs,
  config,
  settings,
  ...
}:
{
  users.groups.kanidm = { };
  users.users.kanidm = {
    isSystemUser = true;
    group = "kanidm";
  };

  services.cloudflared.tunnels.${settings.ingress_tunnel}.ingress = {
    ${settings.sso.domain} = "https://${config.services.kanidm.serverSettings.bindaddress}";
  };

  # NOTE: cloudflare is setup to redirect requests from
  #  byte-sized.fyi/.well-known/webfinger
  #  to
  #  sso.byte-sized.fyi/oauth2/openid/tailscale/.well-known/webfinger

  services.kanidm = {
    enableServer = true;
    package = pkgs.kanidmWithSecretProvisioning_1_8;
    serverSettings = {
      origin = "https://${settings.sso.domain}";
      domain = settings.sso.domain;
      bindaddress = "127.0.0.1:8443";
      tls_chain = config.sops.secrets."kanidm/tlsChain".path;
      tls_key = config.sops.secrets."kanidm/tlsKey".path;
      online_backup = {
        path = "/var/backup/kanidm";
        schedule = settings.backup.prepare.interval_cron;
        versions = 7;
      };
    };
    provision = {
      enable = true;
      groups = {
        git = { };
        tailnet = { };
        mealie_users = { };
        mealie_admins = { };
        immich_users = { };
      };
      # when adding a new user, run `sudo kanidmd recover-account <username>`
      # to generate a new temporary password
      persons = {
        emilia = {
          displayName = "Emilia";
          mailAddresses = [
            "emilia@sso.byte-sized.fyi"
            "emilia@byte-sized.fyi"
            "jaser.emilia@gmail.com"
          ];
          groups = [
            "tailnet"
            "git"
            "mealie_users"
            "mealie_admins"
            "immich_users"
          ];
        };
        mika = {
          displayName = "Mika";
          mailAddresses = [
            "mika@sso.byte-sized.fyi"
            "mika@byte-sized.fyi"
          ];
          groups = [ "mealie_users" ];
        };
        calla = {
          displayName = "Calla";
          mailAddresses = [
            "calla@sso.byte-sized.fyi"
            "calla@byte-sized.fyi"
          ];
          groups = [ "mealie_users" ];
        };
      };
      systems.oauth2 = {
        tailscale = {
          displayName = "tailscale";
          originUrl = "https://login.tailscale.com/a/oauth_response";
          originLanding = "https://tailscale.com/";
          basicSecretFile = config.sops.secrets."kanidm/tailscaleOauthSecret".path;
          allowInsecureClientDisablePkce = true; # tailscale doesn't support PKCE. grrrrrr
          scopeMaps = {
            tailnet = [
              "openid"
              "email"
              "profile"
            ];
          };
        };
        forgejo = {
          displayName = "forgejo";
          originUrl = "https://git.byte-sized.fyi/user/oauth2/SSO/callback";
          originLanding = "https://git.byte-sized.fyi/";
          basicSecretFile = config.sops.secrets."kanidm/forgejoOauthSecret".path;
          scopeMaps = {
            git = [
              "openid"
              "email"
              "profile"
            ];
          };
        };
        mealie = {
          displayName = "mealie";
          originUrl = "https://meals.byte-sized.fyi/login";
          originLanding = "https://meals.byte-sized.fyi/";
          basicSecretFile = config.sops.secrets."kanidm/mealieOauthSecret".path;
          preferShortUsername = true;
          scopeMaps = {
            mealie_users = [
              "openid"
              "email"
              "profile"
              "groups"
            ];
            mealie_admins = [
              "openid"
              "email"
              "profile"
              "groups"
            ];
          };
        };
        immich = {
          displayName = "immich";
          originUrl = [
            "app.immich:///oauth-callback"
            "https://images.byte-sized.fyi/auth/login"
            "https://images.byte-sized.fyi/user-settings"
          ];
          originLanding = "https://images.byte-sized.fyi/";
          basicSecretFile = config.sops.secrets."kanidm/immichOauthSecret".path;
          scopeMaps = {
            immich_users = [
              "openid"
              "email"
              "profile"
            ];
          };
        };
      };
    };
  };
}
