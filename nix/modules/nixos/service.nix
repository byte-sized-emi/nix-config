{ lib, config, ... }:
with lib;
{
  # TODO: Implement a services module.
  # Features:
  # - set backup path, with an optional feature for a preparation step
  # - set a internal services domain with enable option
  # - set a external domain with enable option
  # - create a system user automatically
  # - description for documentation
  # - version?

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
            };

            external = {
              enable = mkEnableOption "Enable external access for the service.";
              domain = mkOption {
                type = types.str;
                default = "${name}.${config.settings.domain}";
              };
              https = mkOption {
                type = types.bool;
                default = false;
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
      inherit (lib)
        pipe
        mapAttrsToList
        groupBy
        filterAttrs
        concatStringsSep
        concatMapStringsSep
        ;
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

      formatDuplicates = concatStringsSep "\n" (
        mapAttrsToList (
          port: services: "  Port ${port}: ${concatMapStringsSep ", " (s: s.name) services}"
        ) duplicatePorts
      );

      backupEnabledServices = pipe config.my.services [
        (filterAttrs (_name: svc: svc.enable && svc.backups.enable))
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
          ${formatDuplicates}
        '';
      }
      {
        assertion = backupEnabledServices == [ ];
        message = ''
          Backups are currently not supported.
          Offending services: ${concatMapStringsSep ", " (s: s.name) backupEnabledServices}
        '';
      }
    ];

  config.environment.etc."stacks/services.json".text = builtins.toJSON (
    filterAttrs (_name: svc: svc.enable) config.my.services
  );

  # config.services.cloudflared.tunnels.${config.settings.ingress_tunnel}.ingress = mkMerge (
  config.services.my-cloudflared.tunnels.${config.settings.ingress_tunnel}.ingress = mkMerge (
    mapAttrsToList (
      _name: serviceCfg:
      mkIf (serviceCfg.enable && serviceCfg.external.enable) {
        ${serviceCfg.external.domain} =
          if serviceCfg.external.https then
            "https://localhost:${toString serviceCfg.port}"
          else
            "http://localhost:${toString serviceCfg.port}";
      }
    ) config.my.services
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

  config.services.caddy.virtualHosts = mkMerge (
    mapAttrsToList (
      _name: serviceCfg:
      mkIf (serviceCfg.enable && serviceCfg.internal.enable) {
        ${serviceCfg.internal.domain}.extraConfig = ''
          import abort_external
          reverse_proxy localhost:${toString serviceCfg.port}
        '';
      }
    ) config.my.services
  );
}
