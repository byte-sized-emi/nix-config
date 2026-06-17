{
  disko.devices = {
    disk = {
      hdd1 = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x50014ee2b6346905";
        content = {
          type = "gpt";
          partitions = {
            a = {
              size = "200G";
              content = {
                type = "zfs";
                pool = "redundant_pool";
              };
            };
            b = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/media1";
                mountOptions = [ "noatime" ];
              };
            };
          };
        };
      };
      hdd2 = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x5000cca720c66029";
        content = {
          type = "gpt";
          partitions = {
            a = {
              size = "200G";
              content = {
                type = "zfs";
                pool = "redundant_pool";
              };
            };
            b = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/media2";
                mountOptions = [ "noatime" ];
              };
            };
          };
        };
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
        mountpoint = "/mnt/redundant_data";
        datasets = { };
      };
    };
    nodev = {
      media = {
        content = {
          type = "filesystem";
          format = "fuse.mergerfs";
          mountpoint = "/mnt/media";
          device = "/mnt/media1:/mnt/media2";
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
