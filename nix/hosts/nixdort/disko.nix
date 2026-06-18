let
  hddRaidConfig =
    { mountpoint }:
    {
      type = "gpt";
      partitions = {
        zfs = {
          size = "300G";
          content = {
            type = "zfs";
            pool = "redundant_pool";
          };
        };
        media = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountOptions = [ "noatime" ];
            inherit mountpoint;
          };
        };
      };
    };
in
{
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
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
      smallhdd = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x50014ee2b6346905";
        content = hddRaidConfig { mountpoint = "/mnt/media1"; };
      };
      hdd1 = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x50014ee6053e7faf";
        content = hddRaidConfig { mountpoint = "/mnt/media2"; };

      };
      hdd2 = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x50014ee2b6407d36";
        content = hddRaidConfig { mountpoint = "/mnt/media3"; };
      };
    };
    zpool = {
      redundant_pool = {
        type = "zpool";
        mode = "raidz1";
        rootFsOptions = {
          compression = "zstd";
          refreservation = "1G"; # reserve a gigabyte of space so the partition is never 100% full
        };
        mountpoint = "/mnt/raid";
        datasets = { };
      };
    };
    nodev = {
      media = {
        content = {
          type = "filesystem";
          format = "fuse.mergerfs";
          mountpoint = "/mnt/media";
          device = "/mnt/media1:/mnt/media2:/mnt/media3";
          mountOptions = [
            "defaults"
            "noatime"
            "cache.files=partial"
            "dropcacheonclose=true"
            "category.create=mfs"
          ];
        };
      };
    };
  };
}
