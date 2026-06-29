{ config, ... }:
{
  my.services.hedgedoc = {
    enable = true;
    description = "Collaborative markdown editing";
    port = 3314;
    external = {
      enable = true;
      domain = "md.byte-sized.fyi";
    };
  };

  sops.secrets."hedgeDoc.env" = { };

  services.hedgedoc = {
    enable = true;
    # environment file also sets NODE_OPTIONS=--use-system-ca
    environmentFile = config.sops.secrets."hedgeDoc.env".path;
    settings = {
      domain = config.my.services.hedgedoc.external.domain;
      port = config.my.services.hedgedoc.port;
      protocolUseSSL = true;
      urlAddPort = false;
      rateLimitUsingCloudflare = true;
      # Allow anonymous users to edit *only* when the note owner allows it.
      allowAnonymous = false;
      allowAnonymousEdits = true;

      enableStatsApi = false;
      oauth2 = rec {
        baseURL = "https://sso.byte-sized.fyi/";
        providerName = "KaniDM SSO";
        clientID = "hedgedoc";
        scope = "openid email profile";
        pkce = true;
        userProfileDisplayNameAttr = "name";
        userProfileUsernameAttr = "preferred_username";
        userProfileEmailAttr = "email";
        userProfileURL = "${baseURL}oauth2/openid/${clientID}/userinfo";
        tokenURL = "${baseURL}oauth2/token";
        authorizationURL = "${baseURL}ui/oauth2";
      };
    };
  };
}
