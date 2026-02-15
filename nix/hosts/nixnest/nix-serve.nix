{ pkgs, config, ... }:
{
  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    port = 7384;
    openFirewall = false;
  };

  services.caddy.virtualHosts.${config.settings.cache.service_domain} = {
    extraConfig = ''
      reverse_proxy localhost:${toString config.services.nix-serve.port}
    '';
  };
}
