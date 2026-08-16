{ lib, ... }:
{
  stacks.freshrss.nixos = { config, pkgs, ... }: {
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
      api.enable = true;
      passwordFile = config.sops.secrets."freshrss/password".path;
      extensions = with pkgs.freshrss-extensions; [
        reading-time
      ];
    };

    services.caddy.virtualHosts.${config.services.freshrss.virtualHost}.extraConfig = lib.mkBefore ''
      import abort_external
    '';
  };
}
