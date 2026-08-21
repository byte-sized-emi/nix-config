{
  den.aspects.control-server.nixos =
    {
      lib,
      config,
      perSystem,
      ...
    }:
    let
      inherit (perSystem.self) control-server;
      inherit (lib) mkOption types;
      serviceUser = "control-server";
      serviceGroup = "control-server";
    in
    {
      options.my.control-server = mkOption {
        description = "The NixOS deployment control plane (nix-control-server) service.";
        type = types.submodule (
          { config, ... }:
          {
            options = {
              package = mkOption {
                type = types.package;
                default = control-server;
              };

              # Base directory for all service data. Created via systemd tmpfiles.
              dataPath = mkOption {
                type = types.str;
                default = "/var/lib/control-server";
                description = "Base directory where all service data is stored.";
              };

              db = mkOption {
                type = types.str;
                default = "${config.dataPath}/state.db";
                description = "SQLite database path. Overrides the default derived from dataPath.";
              };

              # The web UI, agent API and webhook are all served on one socket.
              listenAddress = mkOption {
                type = types.str;
                default = "127.0.0.1";
                description = "Address the HTTP server binds to; keep this on localhost and proxy through caddy.";
              };
              port = mkOption {
                type = types.port;
                default = 8080;
              };

              publicUrl = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Public base URL used as the commit-status target URL.";
              };

              forgejo = {
                api = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Forgejo API base URL, e.g. https://git.example.org/api/v1";
                };
                owner = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                repo = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                branch = mkOption {
                  type = types.str;
                  default = "main";
                };
                buildPath = mkOption {
                  type = types.str;
                  default = ".build-paths.json";
                };
                pollInterval = mkOption {
                  type = types.ints.unsigned;
                  default = 30;
                  description = "How often (seconds) to poll the branch head for new commits.";
                };
                # Secret values are provided indirectly through files (managed
                # outside this module) so they never end up in the Nix store.
                # Each path is a systemd EnvironmentFile that sets FORGEJO_TOKEN.
                tokenPath = mkOption {
                  type = types.str;
                  description = "Absolute path to a file setting FORGEJO_TOKEN=<token>.";
                };
              };

              webhook = {
                path = mkOption {
                  type = types.str;
                  default = "/webhook/forgejo";
                  description = "HTTP path the Forgejo webhook is registered under.";
                };
                secretPath = mkOption {
                  type = types.str;
                  description = "Absolute path to a file setting WEBHOOK_SECRET=<secret>.";
                };
              };
            };
          }
        );
      };

      config =
        let
          cfg = config.my.control-server;
        in
        {
          assertions = [
            {
              assertion = cfg.forgejo.api != null && cfg.forgejo.owner != null && cfg.forgejo.repo != null;
              message = ''
                my.control-server requires forgejo.api, forgejo.owner and forgejo.repo to be set.
              '';
            }
          ];

          users.users.${serviceUser} = {
            isSystemUser = true;
            group = serviceGroup;
          };
          users.groups.${serviceGroup} = { };

          systemd.tmpfiles.rules = [
            "d ${cfg.dataPath} 0755 ${serviceUser} ${serviceGroup} - -"
          ];

          systemd.services.control-server = {
            description = "NixOS deployment control plane";
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              ExecStart = lib.concatStringsSep " " (
                [
                  (lib.getExe cfg.package)
                  "--forgejo-api ${cfg.forgejo.api}"
                  "--forgejo-owner ${cfg.forgejo.owner}"
                  "--forgejo-repo ${cfg.forgejo.repo}"
                  "--branch ${cfg.forgejo.branch}"
                  "--build-path ${cfg.forgejo.buildPath}"
                  "--poll-interval ${toString cfg.forgejo.pollInterval}"
                  "--webhook-path ${cfg.webhook.path}"
                  "--listen ${cfg.listenAddress}:${toString cfg.port}"
                  "--db ${cfg.db}"
                ]
                ++ lib.optionals (cfg.publicUrl != null) [
                  "--public-url ${cfg.publicUrl}"
                ]
              );
              EnvironmentFile = [
                cfg.forgejo.tokenPath
                cfg.webhook.secretPath
              ];
              User = serviceUser;
              Group = serviceGroup;
              Restart = "on-failure";
            };
          };
        };
    };
}
