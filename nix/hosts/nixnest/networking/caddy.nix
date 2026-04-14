{ config, pkgs, ... }:
{
  # reverse proxy setup is done where it is needed
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins =
        let
          # renovate: datasource=go depName=github.com/caddy-dns/cloudflare
          cloudflareDnsVersion = "v0.2.2";
          # renovate: datasource=go depName=github.com/corazawaf/coraza-caddy/v2
          corazaVersion = "v2.5.0";
        in
        [
          "github.com/caddy-dns/cloudflare@${cloudflareDnsVersion}"
          "github.com/corazawaf/coraza-caddy/v2@${corazaVersion}"
        ];
      hash = "sha256-2Gvk5COnVrjRL/VjQ9mmQcHT7CJQMlz8Slec9wX908Q=";
    };
    environmentFile = config.sops.secrets."caddy/secretsEnv".path;
    globalConfig = ''
      acme_dns cloudflare {env.CF_API_TOKEN}
      dns cloudflare {env.CF_API_TOKEN}
      servers {
        trusted_proxies static 127.0.0.1/8
      }
      order coraza_waf first
    '';

    # more virtualHosts are defined in nix/modules/nixos/service.nix
    # or directly in other services for more custom definitions

    # abuse the virtualHosts config to define a template - hey, if it works.
    # client_ip uses either the IP of the remote directly, or the one passed by cloudflared
    virtualHosts."(abort_external)" = {
      extraConfig = ''
        @external not client_ip private_ranges 100.64.0.0/10 fd7a:115c:a1e0::/48
        abort @external
      '';
      logFormat = null;
    };

    virtualHosts."(waf)" = {
      extraConfig =
        let
          gitDomain = config.settings.git.domain;
        in
        ''
          coraza_waf {
            load_owasp_crs
            directives `
              # Custom rules BEFORE CRS loads - remove rules for specific paths
              # Only apply to git domain

              # SecRule REQUEST_HEADERS:Host "@streq ${gitDomain}" \
              # chain,\

              SecRule REQUEST_URI "@beginsWith /api/actions/runner.v1.RunnerService/" \
                "id:1000,\
                phase:1,\
                pass,\
                nolog,\
                t:none,\
                ctl:ruleRemoveById=920420,\
                ctl:ruleRemoveById=932140,\
                ctl:ruleRemoveById=932230,\
                ctl:ruleRemoveById=932235,\
                ctl:ruleRemoveById=932250,\
                ctl:ruleRemoveById=932260,\
                ctl:ruleRemoveById=941160,\
                ctl:ruleRemoveById=941180,\
                ctl:ruleEngine=Off"

              SecRule REQUEST_HEADERS:Host "@streq ${gitDomain}" \
                "id:1001,\
                chain,\
                phase:1,\
                pass,\
                nolog,\
                t:none,\
                ctl:ruleRemoveById=930130,\
                ctl:ruleRemoveById=932140,\
                ctl:ruleRemoveById=932230,\
                ctl:ruleRemoveById=932235,\
                ctl:ruleRemoveById=932250,\
                ctl:ruleRemoveById=932260,\
                ctl:ruleRemoveById=941160,\
                ctl:ruleRemoveById=921150,\
                ctl:ruleRemoveById=920420,\
                ctl:ruleRemoveById=941100,\
                ctl:ruleRemoveById=941180"
              SecRule REQUEST_URI "@rx \.git/"

              SecRule REQUEST_URI "@beginsWith /login/oauth/authorize" \
                "id:1102,\
                phase:1,\
                pass,\
                nolog,\
                t:none,\
                ctl:ruleRemoveById=934110"

              SecRule REQUEST_HEADERS:Host "@streq ${gitDomain}" \
                "id:1002,\
                chain,\
                phase:1,\
                pass,\
                nolog,\
                t:none,\
                ctl:ruleRemoveById=932140,\
                ctl:ruleRemoveById=932230,\
                ctl:ruleRemoveById=932235,\
                ctl:ruleRemoveById=932250,\
                ctl:ruleRemoveById=932260,\
                ctl:ruleRemoveById=941160,\
                ctl:ruleRemoveById=941180"
              SecRule REQUEST_URI "@beginsWith /api/v1/"

              SecRule REQUEST_HEADERS:Host "@streq ${gitDomain}" \
                "id:1003,\
                chain,\
                phase:1,\
                pass,\
                nolog,\
                t:none,\
                ctl:ruleRemoveById=932140,\
                ctl:ruleRemoveById=932230,\
                ctl:ruleRemoveById=932235,\
                ctl:ruleRemoveById=932250,\
                ctl:ruleRemoveById=932260,\
                ctl:ruleRemoveById=941160,\
                ctl:ruleRemoveById=941180"
              SecRule REQUEST_URI "@rx /.*/issues/.*/content"

              # Now load CRS
              Include @coraza.conf-recommended
              Include @crs-setup.conf.example
              Include @owasp_crs/*.conf
              SecRuleEngine On

              SecRuleRemoveById 200002
              SecRuleRemoveById 200003

              SecRuleRemoveById 900200
              SecAction \
                 "id:5001,\
                 phase:1,\
                 pass,\
                 t:none,\
                 nolog,\
                 setvar:'tx.allowed_methods=GET HEAD POST PUT DELETE OPTIONS'"
            `
           }
        '';
      logFormat = null;
    };
  };
}
