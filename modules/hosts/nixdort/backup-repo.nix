{
  den.aspects.nixdort.nixos = {
    services.borgbackup.repos.nixnest-nas-backup = {
      path = "/mnt/backups/nixnest";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH6shq02ZSUmVPjybS2003iZaGIUif+Li8/5DSfMyipj nas_backup"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIopGi9F4+v4lckvFcEv5PmoxKknS3nESZ7jeKFkIoCq byte_sized"
      ];
      quota = "100G";
    };
  };
}
