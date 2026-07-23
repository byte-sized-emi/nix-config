{ config, ... }:
{
  sops.secrets."rclone/fs/url" = { };
  sops.secrets."rclone/fs/user" = { };
  sops.secrets."rclone/fs/pass" = { };

  home.shellAliases = {
    mount-fachschaft = "rclone mount fachschaft:/ /home/emilia/mnt/fs --vfs-cache-mode=writes &";
    umount-fachschaft = "fusermount -u /home/emilia/mnt/fs";
  };

  programs.rclone = {
    enable = true;
    remotes.fachschaft = {
      config = {
        type = "webdav";
        vendor = "nextcloud";
      };

      secrets = {
        url = config.sops.secrets."rclone/fs/url".path;
        user = config.sops.secrets."rclone/fs/user".path;
        pass = config.sops.secrets."rclone/fs/pass".path;
      };
    };
  };

}
