{ perSystem, config, ... }:
let
  # cloudflare origin certificates
  cert = config.sops.secrets."caddy/links_byte_sized_fyi/cert.pem".path;
  key = config.sops.secrets."caddy/links_byte_sized_fyi/key.pem".path;
in
{
  my.services.linktree = {
    enable = true;
    port = 443;
    external = {
      enable = true;
      https = true;
      domain = "${config.settings.linktree.domain}";
    };
  };

  services.caddy.virtualHosts."${config.settings.linktree.domain}".extraConfig = ''
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
