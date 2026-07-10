{
  boot.supportedFilesystems = [ "btrfs" ];

  # Disks:
  # - 250GB Boot SSD /dev/disk/by-id/wwn-0x500a07510c876ff4
  # - 1TB smallhdd   /dev/disk/by-id/wwn-0x50014ee2b6346905
  # - 2TB HDD1       /dev/disk/by-id/wwn-0x50014ee6053e7faf
  # - 2TB HDD2       /dev/disk/by-id/wwn-0x50014ee2b6407d36
  disko.devices = {
    disk = {
      bootssd = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x500a07510c876ff4";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "filesystem";
                  format = "ext4";
                  extraArgs = [
                    "-L"
                    "cryptroot"
                  ];
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
      hdd1 = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x50014ee6053e7faf";
        content = {
          type = "gpt";
          partitions = {
            media = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypt1";
                settings = {
                  keyFile = "/var/lib/luks/key:LABEL=cryptroot";
                };
              };
            };
          };
        };
      };
      hdd2 = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x50014ee2b6407d36";
        content = {
          type = "gpt";
          partitions = {
            media = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypt2";
                settings = {
                  keyFile = "/var/lib/luks/key:LABEL=cryptroot";
                };
              };
            };
          };
        };
      };
      smallhdd = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x50014ee2b6346905";
        content = {
          type = "gpt";
          partitions = {
            media = {
              size = "100%";
              content = {
                type = "luks";
                name = "mediarypt3";
                settings = {
                  keyFile = "/var/lib/luks/key:LABEL=cryptroot";
                };
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-d"
                    "raid5"
                    "-m"
                    "raid1"
                    "/dev/mapper/crypt1"
                    "/dev/mapper/crypt2"
                  ];
                  subvolumes = {
                    "/backups" = {
                      mountpoint = "/mnt/backups";
                      mountOptions = [
                        "defaults"
                        "noatime"
                        "nossd"
                      ];
                    };
                    "/media" = {
                      mountpoint = "/mnt/media";
                      mountOptions = [
                        "defaults"
                        "noatime"
                        "nossd"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
