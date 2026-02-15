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
              };
            };

            external = {
              enable = mkEnableOption "Enable external access for the service.";
              domain = mkOption {
                type = types.str;
              };
            };

            backups = {
              enable = mkEnableOption "Enable automatic backups for the service.";
              path = mkOption {
                type = types.str;
              };
              prepare = {
                enable = mkEnableOption "Enable a preparation step before backup.";
                interval = mkOption {
                  type = types.str;
                };
                action = mkOption {
                  type = types.oneOf [
                    types.str
                    types.pathInStore
                    types.derivation
                  ];
                };
              };
            };
          };
        }
      )
    );
  };

  config.services.cloudflared.tunnels.${config.settings.ingress_tunnel}.ingress = mkMerge (
    mapAttrsToList (
      _name: serviceCfg:
      mkIf serviceCfg.external.enable {
        ${serviceCfg.external.domain} = "http://localhost:${toString serviceCfg.port}";
      }
    ) config.my.services
  );

  config.users = mkMerge (
    mapAttrsToList (
      _name: serviceCfg:
      mkIf serviceCfg.createSystemUser {
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
      mkIf serviceCfg.internal.enable {
        ${serviceCfg.internal.domain}.extraConfig = ''
          reverse_proxy localhost:${toString serviceCfg.port}
        '';
      }
    ) config.my.services
  );

}
