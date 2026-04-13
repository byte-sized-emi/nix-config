{
  perSystem,
  config,
  lib,
  ...
}:
let
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
    root * ${perSystem.self.linktree}
    file_server {
      etag_file_extensions .etag
    }
  '';
}
