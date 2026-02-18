{
  config,
  pkgs,
  ...
}:
{
  systemd.timers."prepare-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = config.settings.backup.prepare.interval;
      Persistent = true;
    };
  };

  systemd.services."prepare-backup" = {
    script = ''
      shopt -s expand_aliases
      alias podman=${config.virtualisation.podman.package}/bin/podman
      alias tar=${pkgs.gnutar}/bin/tar
      alias gzip=${pkgs.gzip}/bin/gzip

      rm -rf /var/backup/mealie/ /var/backup/immich_db/
      mkdir /var/backup/mealie/
      mkdir /var/backup/immich_db/
      podman volume export mealie-data | tar xf - -C /var/backup/mealie/
      podman exec -t immich-database pg_dumpall --clean --if-exists --username=postgres | gzip > "/var/backup/immich_db/dump.sql.gz"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  users.groups.borg = { };
  users.users.borg = {
    isSystemUser = true;
    group = "borg";
    createHome = true;
    home = "/var/borghome";
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

  systemd.services.borgbackup-job-nixnest.serviceConfig = {
    # read-only access to every file on the filesystem
    AmbientCapabilities = "CAP_DAC_READ_SEARCH";
  };
}
