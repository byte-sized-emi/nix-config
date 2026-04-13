{ lib, config, ... }:
with lib;
{
  # TODO:
  # - set backup path, with an optional feature for a preparation step

  options.my.services = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            enable = mkEnableOption "Enable the service.";
            version = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            description = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            name = mkOption {
              type = types.str;
              default = name;
            };

            port = mkOption {
              type = types.port;
            };
            https.enable = mkOption {
              type = types.bool;
              default = false;
            };
            https.certificate = mkOption {
              type = types.nullOr types.path;
              default = null;
            };

            createSystemUser = mkOption {
              type = types.bool;
              default = false;
            };

            internal = {
              enable = mkEnableOption "Enable internal access for the service.";
              domain = mkOption {
                type = types.str;
                default = "${name}.${config.settings.services.domain}";
              };
              caddyExtraConfig = mkOption {
                type = types.str;
                description = "Caddy config inside the site block of this domain.";
                default = "";
              };
            };

            external = {
              enable = mkEnableOption "Enable external access for the service.";
              domain = mkOption {
                type = types.str;
                default = "${name}.${config.settings.domain}";
              };
              caddyExtraConfig = mkOption {
                type = types.str;
                description = "Caddy config inside the site block of this domain.";
                default = "";
              };
            };

            backups = {
              enable = mkEnableOption "Enable automatic backups for the service.";
              paths = mkOption {
                type = types.listOf types.str;
                default = [ ];
              };
              prepare = {
                enable = mkEnableOption "Enable a preparation step before backup.";
                action = mkOption {
                  type = types.nullOr (
                    types.oneOf [
                      types.str
                      types.package
                    ]
                  );
                  default = null;
                };
              };
            };
          };
        }
      )
    );
  };

  config.assertions =
    let
      duplicatePorts = pipe config.my.services [
        (filterAttrs (_name: svc: svc.enable))
        (mapAttrsToList (
          _name: svc: {
            inherit (svc) name port;
          }
        ))
        (groupBy (svc: toString svc.port))
        (filterAttrs (_port: services: builtins.length services > 1))
      ];

      formatDuplicatePorts = concatStringsSep "\n" (
        mapAttrsToList (
          port: services: "  Port ${port}: ${concatMapStringsSep ", " (s: s.name) services}"
        ) duplicatePorts
      );

      duplicateDomains = pipe config.my.services [
        (filterAttrs (_name: svc: svc.enable && (svc.external.enable || svc.internal.enable)))
        (mapAttrsToList (
          _name: svc: [
            {
              inherit (svc) name;
              inherit (svc.internal) domain enable;
            }
            {
              inherit (svc) name;
              inherit (svc.external) domain enable;
            }
          ]
        ))
        flatten
        (filter (svc: svc.enable))
        (groupBy (svc: svc.domain))
        (filterAttrs (_domain: services: builtins.length services > 1))
      ];

      formatDuplicateDomains = concatStringsSep "\n" (
        mapAttrsToList (
          domain: services: "  Domain ${domain}: ${concatMapStringsSep ", " (s: s.name) services}"
        ) duplicateDomains
      );

      backupEnabledServices = pipe config.my.services [
        (filterAttrs (_name: svc: svc.enable && svc.backups.enable))
        (mapAttrsToList (
          _name: svc: {
            inherit (svc) name;
          }
        ))
      ];

      missingHttpsCertServices = pipe config.my.services [
        (filterAttrs (_name: svc: svc.enable && svc.https.enable && svc.https.certificate == null))
        (mapAttrsToList (
          _name: svc: {
            inherit (svc) name;
          }
        ))
      ];
    in
    [
      {
        assertion = duplicatePorts == { };
        message = ''
          Duplicate ports found in my.services configuration!
          The following ports are used by multiple services:
          ${formatDuplicatePorts}
        '';
      }
      {
        assertion = duplicateDomains == { };
        message = ''
          Duplicate domains found in my.services configuration!
          The following domains are used by multiple services:
          ${formatDuplicateDomains}
        '';
      }
      {
        assertion = backupEnabledServices == [ ];
        message = ''
          Backups are currently not supported.
          Offending services: ${concatMapStringsSep ", " (s: s.name) backupEnabledServices}
        '';
      }
      {
        assertion = missingHttpsCertServices == [ ];
        message = ''
          The following services have HTTPS enabled but no certificate specified:
          ${concatMapStringsSep ", " (s: s.name) missingHttpsCertServices}
        '';
      }
    ];

  config.environment.etc."stacks/services.json".text = builtins.toJSON (
    filterAttrs (_name: svc: svc.enable) config.my.services
  );

  config.users = mkMerge (
    mapAttrsToList (
      _name: serviceCfg:
      mkIf (serviceCfg.enable && serviceCfg.createSystemUser) {
        users.${serviceCfg.name} = {
          isSystemUser = true;
          group = serviceCfg.name;
        };
        groups.${serviceCfg.name} = { };
      }
    ) config.my.services
  );

  # config.services.cloudflared.tunnels.${config.settings.ingress_tunnel}.ingress = mkMerge (
  # config.services.my-cloudflared.tunnels.${config.settings.ingress_tunnel}.ingress = mkMerge (
  #   mapAttrsToList (
  #     _name: serviceCfg:
  #     mkIf (serviceCfg.enable && serviceCfg.external.enable) {
  #       ${serviceCfg.external.domain} =
  #         if serviceCfg.https.enable then
  #           "https://localhost:${toString serviceCfg.port}"
  #         else
  #           "http://localhost:${toString serviceCfg.port}";
  #     }
  #   ) config.my.services
  # );

  # TODO: Add "import waf" to all external requests
  config.services.caddy.virtualHosts =
    let
      mkInternalService =
        _name: serviceCfg:
        mkIf (serviceCfg.enable && serviceCfg.internal.enable) {
          ${serviceCfg.internal.domain}.extraConfig = ''
            import abort_external
            ${serviceCfg.internal.caddyExtraConfig}
            reverse_proxy localhost:${toString serviceCfg.port}
          '';
        };
      internalServices = mapAttrsToList mkInternalService config.my.services;
      mkExternalService =
        _name: serviceCfg:
        mkIf (serviceCfg.enable && serviceCfg.external.enable) {
          ${serviceCfg.external.domain}.extraConfig =
            let
              originCert = "/etc/certs/wildcard_origin_cert.pem";
              originKey = config.sops.secrets."caddy/origincert_byte_sized_fyi/key.pem".path;
              reverseProxyConfig =
                if serviceCfg.https.enable && serviceCfg.https.certificate != null then
                  ''
                    reverse_proxy https://localhost:${toString serviceCfg.port} {
                      transport http {
                        tls_trust_pool file ${serviceCfg.https.certificate}
                        tls_server_name ${serviceCfg.external.domain}
                      }
                    }
                  ''
                else
                  "reverse_proxy http://localhost:${toString serviceCfg.port}";
            in
            ''
              import waf
              tls ${originCert} ${originKey}
              ${serviceCfg.external.caddyExtraConfig}
              ${reverseProxyConfig}
            '';
        };
      externalServices = mapAttrsToList mkExternalService config.my.services;
    in
    mkMerge (internalServices ++ externalServices);
}
