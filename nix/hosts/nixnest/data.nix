{
  boot.supportedFilesystems = [ "nfs" ];

  fileSystems."/mnt/media" = {
    device = "nixdort:/media";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "nofail"
      "noexec"
    ];
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/77b18384-24cf-49cf-92b3-f51b9696846d";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
      "noexec"
    ];
  };
}
