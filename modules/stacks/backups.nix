{
  stacks.backups.nixos =
    { config, pkgs, ... }:
    let
      prepareBackupApp = pkgs.writeShellApplication {
        name = "prepare-backup";
        runtimeInputs = [
          config.virtualisation.podman.package
          pkgs.gnutar
          pkgs.gzip
        ];
        text = ''
          rm -rf /var/backup/mealie/ /var/backup/immich_db/ /var/backup/umami_db/ /var/backup/dawarich_db/
          mkdir /var/backup/mealie/ /var/backup/immich_db/ /var/backup/umami_db/ /var/backup/dawarich_db/
          podman volume export mealie-data | tar xf - -C /var/backup/mealie/
          podman exec -t immich-database pg_dumpall --clean --if-exists --username=postgres | gzip > "/var/backup/immich_db/dump.sql.gz"
          podman exec -t umami-db pg_dumpall --clean --if-exists --username=postgres | gzip > "/var/backup/umami_db/dump.sql.gz"
          podman exec -t dawarich-db pg_dumpall --clean --if-exists --username=postgres | gzip > "/var/backup/dawarich_db/dump.sql.gz"
        '';
      };
      prepareBackupScript = pkgs.lib.getExe prepareBackupApp;
    in
    {
      sops.secrets."borg/backupKey" = {
        owner = config.users.users.borg.name;
        group = config.users.groups.borg.name;
      };
      sops.secrets."ssh_keys/nas_backup/priv" = {
        owner = config.users.users.borg.name;
        group = config.users.groups.borg.name;
      };

      # Backup pruning:
      # borg prune ssh://d0804253@d0804253.repo.borgbase.com/./repo --dry-run --list -v --keep-weekly 5 --keep-monthly 5 --keep-13weekly 3 --keep-yearly 2
      systemd.timers."prepare-backup" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = config.settings.backup.prepare.interval;
          Persistent = true;
        };
      };

      systemd.services =
        let
          serviceConfig = {
            ReadOnlyPaths = [
              "/var/immich/upload_location"
              config.sops.secrets."borg/backupKey".path
              config.sops.secrets."ssh_keys/nas_backup/priv".path
            ];
            # read-only access to every file on the filesystem - should be unnecessary with the above option?
            AmbientCapabilities = "CAP_DAC_READ_SEARCH";
          };
        in
        {
          borgbackup-job-nixnest = { inherit serviceConfig; };
          borgbackup-job-nixnest-nas-backup = { inherit serviceConfig; };
          prepare-backup = {
            serviceConfig = {
              ExecStart = prepareBackupScript;
              Type = "oneshot";
              User = "root";
            };
          };
        };

      users.groups.borg = { };
      users.users.borg = {
        isSystemUser = true;
        group = "borg";
        createHome = true;
        home = "/var/borghome";
        extraGroups = [ "podman" ];
      };

      programs.ssh.knownHosts = {
        "d0804253.repo.borgbase.com/ed25519" = {
          hostNames = [ "d0804253.repo.borgbase.com" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS3185JdDy7ffnr0nLWqVy8FaAQeVh1QYUSiNpW5ESq";
        };
        "d0804253.repo.borgbase.com/rsa" = {
          hostNames = [ "d0804253.repo.borgbase.com" ];
          publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwHsO5g7kAEpqcK4bpHCUKYV1cKCUNwVEVsDQyfj7N8L92E21n+aEhIX2Nh/kFs1W9D/pgsWQBAbco9e/ORuagHrO8hUQtbda5Z31PAo4eipwP17VQr5rF3seaJJNFV72v89PGwMOWQwvoJte+yngC6PYGKJ+w63SRtflihAmf4xa5Tci/f6jbX6t32m2F3bnephVzQO6anGXvGPR8QYQXzSu/27+LaKnLd2Kugb1Ytbo0+6kioa60HWejIZ/mCrCHXYpi0jAllaYEuAsTqFWf/OFUHrKWwRAJD0TV43O1++vLlxY85oQxIgc4oUbm93dXmDBssrTnqqq2jqonteUr";
        };
        "d0804253.repo.borgbase.com/ecdsa-sha2-nistp256" = {
          hostNames = [ "d0804253.repo.borgbase.com" ];
          publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOstKfBbwVOYQh3J7X4nzd6/VYgLfaucP9z5n4cpSzcZAOKGh6jH8e1mhQ4YupthlsdPKyFFZ3pKo4mTaRRuiJo=";
        };
        "[192.168.0.204]:2222" = {
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMezII1cT3PA1BZaU/wWawE30gjfuPYm7K2tDLx6ZlAb";
        };
      };

      services.borgbackup.jobs.nixnest = {
        paths = [
          "/var/backup"
          # NOTE: This stores both the images as well as automatic database dumps (inside ./backups).
          #   If these get too big, you can change the settings in the admin menu
          "/var/immich/upload_location"
        ];
        environment.BORG_RSH = "ssh -i /home/emilia/.ssh/id_borgbase";
        repo = "ssh://d0804253@d0804253.repo.borgbase.com/./repo";
        compression = "auto,zstd";
        startAt = config.settings.backup.interval;
        encryption = {
          mode = "repokey";
          passCommand = "cat ${config.sops.secrets."borg/backupKey".path}";
        };
        persistentTimer = true;
        user = "borg";
        group = "borg";
      };

      services.borgbackup.jobs.nixnest-nas-backup = {
        paths = [
          "/var/backup"
          "/var/immich/upload_location"
        ];
        environment.BORG_RSH = "ssh -i ${config.sops.secrets."ssh_keys/nas_backup/priv".path} -p 2222";
        repo = "ssh://borg@192.168.0.204/./.";
        compression = "auto,zstd";
        startAt = config.settings.backup.local.interval;
        encryption = {
          mode = "repokey";
          passCommand = "cat ${config.sops.secrets."borg/backupKey".path}";
        };
        readWritePaths = [
          "/var/backup"
          "/var/lib/containers/"
          "/run/"
        ];
        preHook = ''
          ${prepareBackupScript}
        '';
        # "borg help prune" for informatino
        prune.keep = {
          within = "1w"; # Keep all archives from the last week
          daily = 7;
          weekly = 5;
          monthly = 4; # Keep at least one archive for the last four months
          "13weekly" = 3; # one archive for the last 3 quarters
          yearly = -1; # one archive per year
        };
        # user = "borg";
        # group = "borg";
      };
    };
}
