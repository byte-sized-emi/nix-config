{
  den.aspects.backup-registry.nixos =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    with lib;
    let
      enabledBackups = filterAttrs (_: b: b.enable) config.my.backups;

      mkPrepareScript =
        name: backup:
        let
          postgresStep = optionalString (backup.postgresContainer != null) ''
            podman exec -t ${escapeShellArg backup.postgresContainer.containerName} \
              pg_dumpall --clean --if-exists \
              --username=${escapeShellArg backup.postgresContainer.username} \
              | gzip > ${escapeShellArg "${backup.workDir}/dump.sql.gz"}
          '';
        in
        pkgs.writeShellApplication {
          name = "backup-prepare-${name}";
          runtimeInputs = [
            config.virtualisation.podman.package
            pkgs.gnutar
            pkgs.gzip
          ]
          ++ backup.runtimeInputs;
          text = ''
            rm -rf ${escapeShellArg backup.workDir} && mkdir -p ${escapeShellArg backup.workDir}
            ${backup.prepareCommands backup.workDir}
            ${postgresStep}
          '';
        };

      prepareScripts = mapAttrs mkPrepareScript enabledBackups;

      prepareAllScript = pkgs.writeShellApplication {
        name = "backup-prepare-all";
        text = ''
          echo "Starting backup preparation"

          failed=0
          ${concatStringsSep "\n" (
            mapAttrsToList (name: script: ''
              echo "--- backup-prepare: ${name} ---"
              if ! ${getExe script}; then
                echo "ERROR: backup-prepare-${name} failed" >&2
                failed=$((failed + 1))
              fi
            '') prepareScripts
          )}
          if [ "$failed" -gt 0 ]; then
            echo "WARNING: $failed backup prepare step(s) failed" >&2
          fi

          echo "Backup preparation completed"
        '';
      };
    in
    {
      options.my.backups = mkOption {
        default = { };
        description = ''
          Central backup registry. Each entry describes how to prepare artifacts
          for borgbackup. The generated prepare scripts are run by the
          prepare-backup systemd service and can also be used as a borg preHook.
        '';
        type = types.attrsOf (
          types.submodule (
            { name, ... }:
            {
              options = {
                enable = mkEnableOption "Enable this backup entry.";

                workDir = mkOption {
                  type = types.externalPath;
                  default = "/var/backup/${name}";
                  description = "Directory wiped and repopulated by the prepare script before each backup. The postgres shorthand writes its dump here.";
                };

                paths = mkOption {
                  type = types.listOf types.externalPath;
                  default = [ ];
                  description = "Live data paths borg backs up directly. Not cleaned or prepared.";
                };

                runtimeInputs = mkOption {
                  type = types.listOf types.package;
                  default = [ ];
                  description = ''
                    Extra packages added to PATH in the prepare script. The script already
                    includes podman, gnutar, and gzip. Add anything else required by
                    prepareCommands here, e.g. pkgs.curl.
                  '';
                };

                prepareCommands =
                  let
                    workDirToCmd = types.functionTo types.lines;
                    coerceFunc = lines: (_: lines);
                    prepareCommandsType = types.coercedTo types.lines coerceFunc workDirToCmd;
                  in
                  mkOption {
                    type = prepareCommandsType;
                    default = _: "";
                    example = literalExpression "workDir: \"cp -r /some/folder $\{workDir}\"";
                    description = "Shell commands run to produce artifacts inside workDir. May span multiple lines. Can be defined as a function that takes in `workDir`.";
                  };

                postgresContainer = mkOption {
                  type = types.nullOr (
                    types.submodule {
                      options = {
                        containerName = mkOption {
                          type = types.str;
                          description = "Name of the podman container running PostgreSQL.";
                        };
                        username = mkOption {
                          type = types.str;
                          default = "postgres";
                          description = "PostgreSQL user passed to pg_dumpall.";
                        };
                      };
                    }
                  );
                  default = null;
                  description = ''
                    Shorthand for backing up a podman-hosted PostgreSQL container via
                    pg_dumpall. Produces a compressed dump at workDir/dump.sql.gz.
                  '';
                };
              };
            }
          )
        );
      };

      options.my.backup.extraPaths = mkOption {
        type = types.listOf types.externalPath;
        readOnly = true;
        internal = true;
        description = "Aggregated raw paths from all enabled backup entries, for use in borg job path lists.";
      };

      options.my.backup.prepareAllScript = mkOption {
        type = types.package;
        readOnly = true;
        internal = true;
        description = "Generated script that runs all registered backup prepare steps.";
      };

      config = {
        my.backup.extraPaths = concatMap (b: b.paths) (attrValues enabledBackups);
        my.backup.prepareAllScript = prepareAllScript;

        systemd.services.prepare-backup = {
          serviceConfig = {
            ExecStart = getExe prepareAllScript;
            Type = "oneshot";
            User = "root";
          };
        };
      };
    };
}
