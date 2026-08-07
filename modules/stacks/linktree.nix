{ inputs, lib, ... }:
{
  stacks.linktree.nixos =
    { pkgs, config, ... }:
    let
      system = pkgs.stdenvNoCC.hostPlatform.system;
      perSystem = lib.mapAttrs (
        name: input: (input.legacyPackages.${system} or input.packages.${system} or { })
      ) inputs;
      linktree = perSystem.self.linktree;
      # cloudflare origin certificates
      cert = "/etc/certs/links_byte_sized_fyi_origin_cert.pem";
      key = config.sops.secrets."caddy/links_byte_sized_fyi/key.pem".path;
    in
    {
      my.services.linktree = {
        enable = true;
        port = 443;
        https = {
          enable = true;
          certificate = cert;
        };
        external = {
          enable = true;
          domain = config.settings.linktree.domain;
        };
      };

      services.caddy.virtualHosts."${config.settings.linktree.domain}".extraConfig = lib.mkForce ''
        header {
          -Last-Modified
        }
        tls ${cert} ${key}
        encode
        root * ${linktree}
        file_server {
          etag_file_extensions .etag
        }
      '';
    };
}
