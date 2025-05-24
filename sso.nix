{ pkgs, config, settings, ... }:

{
  users.groups.kanidm = {};
  users.users.kanidm = {
    isSystemUser = true;
    group = "kanidm";
  };

  # TODO: backups

  # NOTE: cloudflare is setup to redirect requests from
  #  byte-sized.fyi/.well-known/webfinger
  #  to
  #  sso.byte-sized.fyi/oauth2/openid/tailscale/.well-known/webfinger

  services.kanidm = {
    enableServer = true;
    package = pkgs.kanidmWithSecretProvisioning;
    serverSettings = {
      origin = "https://${settings.sso.domain}";
      domain = settings.sso.domain;
      bindaddress = "127.0.0.1:8443";
      tls_chain = "/var/cloudflare-creds/cert.pem";
      tls_key = "/var/cloudflare-creds/private.pem";
    };
    provision = {
      enable = true;
      groups.tailnet = { };
      persons.emilia = {
        displayName = "Emilia";
        mailAddresses = [ "emilia@sso.byte-sized.fyi" "jaser.emilia@gmail.com" ];
        groups = [ "tailnet" ];
      };
      systems.oauth2 = {
        tailscale = {
          displayName = "tailscale";
          originUrl = "https://login.tailscale.com/a/oauth_response";
          originLanding = "https://tailscale.com/";
          basicSecretFile = "/var/tailscale/oauth_secret";
          allowInsecureClientDisablePkce = true;
          scopeMaps = {
            tailnet = [
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
