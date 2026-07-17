{ config, pkgs, ... }:
{
  sops.secrets."caddy/secretsEnv".owner = config.users.users.caddy.name;
  sops.secrets."caddy/links_byte_sized_fyi/key.pem".owner = config.users.users.caddy.name;
  sops.secrets."caddy/origincert_byte_sized_fyi/key.pem".owner = config.users.users.caddy.name;
  sops.secrets."caddy/self_signed_cert/key.pem".owner = config.users.users.kanidm.name;

  # reverse proxy setup is done where it is needed
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins =
        let
          # renovate: datasource=go depName=github.com/caddy-dns/cloudflare
          cloudflareDnsVersion = "v0.2.4";
        in
        [
          "github.com/caddy-dns/cloudflare@${cloudflareDnsVersion}"
        ];
      hash = "sha256-hEHgAG0F0ozHRAPuxEqLyTATBrE+pajeXDiSNwniorg=";
    };
    environmentFile = config.sops.secrets."caddy/secretsEnv".path;
    globalConfig = ''
      acme_dns cloudflare {env.CF_API_TOKEN}
      dns cloudflare {env.CF_API_TOKEN}
      servers {
        trusted_proxies static 127.0.0.1/8
      }
    '';

    # more virtualHosts are defined in nix/modules/nixos/service.nix
    # or directly in other services for more custom definitions

    virtualHosts."*.byte-sized.fyi" = {
      extraConfig = ''
        redir https://links.byte-sized.fyi
      '';
    };

    # abuse the virtualHosts config to define a template - hey, if it works.
    # client_ip uses either the IP of the remote directly, or the one passed by cloudflared
    virtualHosts."(abort_external)" = {
      extraConfig = ''
        @external not client_ip private_ranges 100.64.0.0/10 fd7a:115c:a1e0::/48
        abort @external
      '';
      logFormat = null;
    };
  };
}
