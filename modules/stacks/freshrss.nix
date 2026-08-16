{ lib, ... }:
{
  stacks.freshrss.nixos = { config, ... }: {
    sops.secrets."freshrss/password" = {
      owner = "freshrss";
      group = "freshrss";
    };

    services.freshrss = {
      enable = true;
      virtualHost = "freshrss.${config.settings.services.domain}";
      baseUrl = "https://freshrss.${config.settings.services.domain}";
      webserver = "caddy";
      defaultUser = "emilia";
      passwordFile = config.sops.secrets."freshrss/password".path;
    };

    services.caddy.virtualHosts.${config.services.freshrss.virtualHost}.extraConfig = lib.mkBefore ''
      import abort_external
    '';
  };
}
