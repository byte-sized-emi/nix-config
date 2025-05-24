{ pkgs, config, settings, ... }:

{
  users.groups.kanidm = {};
  users.users.kanidm = {
    isSystemUser = true;
    group = "kanidm";
  };

  # TODO: backups

  services.kanidm = {
    enableServer = true;
    package = pkgs.kanidm_1_5;
    serverSettings = {
      origin = "https://${settings.sso.domain}";
      domain = settings.sso.domain;
      bindaddress = "127.0.0.1:8443";
      tls_chain = "/var/cloudflare-creds/cert.pem";
      tls_key = "/var/cloudflare-creds/private.pem";
    };
    provision = {
      enable = true;
      persons.emilia = {
        displayName = "Emilia";
        mailAddresses = [ "jaser.emilia@gmail.com" ];
      };
    };
  };
}
