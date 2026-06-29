{
  pkgs,
  config,
  ...
}:
let
  port = 8443;
  kanidmUser = config.users.users.kanidm.name;
in
{
  sops.secrets."kanidm/tlsChain".owner = kanidmUser;
  sops.secrets."kanidm/tlsKey".owner = kanidmUser;
  sops.secrets."kanidm/idmAdminPW".owner = kanidmUser;
  sops.secrets."kanidm/tailscaleOauthSecret".owner = kanidmUser;
  sops.secrets."kanidm/forgejoOauthSecret".owner = kanidmUser;
  sops.secrets."kanidm/mealieOauthSecret".owner = kanidmUser;
  sops.secrets."kanidm/immichOauthSecret".owner = kanidmUser;
  sops.secrets."kanidm/jellyfinOauthSecret".owner = kanidmUser;
  sops.secrets."kanidm/hedgedocOauthSecret".owner = kanidmUser;
  sops.secrets."kanidm/mealieOauthSecretEnv".owner = "root";
  # sops.secrets."kanidm/grafanaOauthSecret".owner = kanidmUser;
  # sops.secrets."grafana/OauthSecret" = {
  #   key = "kanidm/grafanaOauthSecret";
  #   owner = config.users.users.grafana.name;
  # };

  my.services.kanidm = {
    enable = true;
    name = "Kanidm";
    inherit port;
    createSystemUser = true;
    description = "Identity management service";
    https = {
      enable = true;
      certificate = "/etc/certs/self_signed.pem";
    };
    external = {
      enable = true;
      domain = config.settings.sso.domain;
    };
  };

  # NOTE: cloudflare is setup to redirect requests from
  #  byte-sized.fyi/.well-known/webfinger
  #  to
  #  sso.byte-sized.fyi/oauth2/openid/tailscale/.well-known/webfinger

  systemd.services.kanidm.serviceConfig.Restart = "always";

  services.kanidm = {
    package = pkgs.kanidmWithSecretProvisioning_1_10; # also update modules/nixos/user.nix
    server = {
      enable = true;
      settings = {
        origin = "https://${config.settings.sso.domain}";
        domain = config.settings.sso.domain;
        bindaddress = "127.0.0.1:${toString port}";
        tls_chain = "/etc/certs/self_signed.pem";
        tls_key = config.sops.secrets."caddy/self_signed_cert/key.pem".path;
        online_backup = {
          path = "/var/backup/kanidm";
          schedule = config.settings.backup.prepare.interval_cron;
          versions = 7;
        };
      };
    };
    provision = {
      enable = true;
      idmAdminPasswordFile = config.sops.secrets."kanidm/idmAdminPW".path;
      groups = {
        git = { };
        tailnet = { };
        mealie_users = { };
        mealie_admins = { };
        immich_users = { };
        media = { };
        media_admins = { };
        hedgedoc_users = { };
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
            "media"
            "media_admins"
            "hedgedoc_users"
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
        danlp6 = {
          displayName = "Dan";
          mailAddresses = [
            "danlp6@sso.byte-sized.fyi"
            "danlp6@byte-sized.fyi"
          ];
          groups = [ "git" ];
        };
        sasha = {
          displayName = "sasa";
          mailAddresses = [
            "sasha@sso.byte-sized.fyi"
            "sasha@byte-sized.fyi"
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
              "groups"
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
        jellyfin = {
          displayName = "JellyFin Media Server";
          originUrl = [
            "https://${config.settings.media.service_domain}/sso/OID/start/kanidm"
            "https://${config.settings.media.service_domain}/sso/OID/redirect/kanidm"
          ];
          originLanding = "https://${config.settings.media.service_domain}/sso/OID/start/kanidm";
          basicSecretFile = config.sops.secrets."kanidm/jellyfinOauthSecret".path;
          scopeMaps = {
            media = [
              "openid"
              "email"
              "profile"
              "groups_name"
            ];
            media_admins = [
              "openid"
              "email"
              "profile"
              "groups_name"
            ];
          };
          preferShortUsername = true;
        };
        hedgedoc = {
          displayName = "HedgeDoc collaborative MarkDown editing";
          originUrl = "https://${config.services.hedgedoc.settings.domain}/auth/oauth2/callback";
          originLanding = "https://${config.services.hedgedoc.settings.domain}";
          basicSecretFile = config.sops.secrets."kanidm/hedgedocOauthSecret".path;
          scopeMaps = {
            hedgedoc_users = [
              "openid"
              "email"
              "profile"
            ];
          };
        };
        # grafana = {
        #   displayName = "grafana";
        #   originUrl = "https://grafana.${config.settings.services.domain}/login/generic_oauth";
        #   originLanding = "https://grafana.${config.settings.services.domain}/";
        #   basicSecretFile = config.sops.secrets."kanidm/grafanaOauthSecret".path;
        #   scopeMaps = { };
        # };
      };
    };
  };
}
