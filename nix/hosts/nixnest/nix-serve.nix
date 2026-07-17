{ pkgs, config, ... }:
{
  my.services.nix-serve = {
    enable = false;
    name = "Nix Serve";
    port = config.services.nix-serve.port;
    description = "Nix package repository and file server";
    internal = {
      enable = true;
      domain = config.settings.cache.service_domain;
    };
  };

  services.nix-serve = {
    enable = false;
    package = pkgs.nix-serve-ng;
    port = 7384;
    openFirewall = false;
  };
}
