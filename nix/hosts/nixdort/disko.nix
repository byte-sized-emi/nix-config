{ lib, pkgs, ... }:
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
  # nix run github:nix-community/nixos-anywhere -- --flake '.#nixdort' --generate-hardware-config nixos-generate-config ./nix/hosts/nixdort/hardware-configuration.nix --target-host nixos@192.168.0.225
  # nix run github:nix-community/nixos-anywhere -- --flake '.#nixdort' --generate-hardware-config nixos-generate-config ./nix/hosts/nixdort/hardware-configuration.nix --target-host nixos@192.168.0.225 --phases install,reboot --disko-mode mount
  fileSystems."/mnt/media".noCheck = lib.mkForce true;

  # we don't really need the zfs pool to be mounted at boot time, so this might be unnecessary?
  environment.systemPackages = with pkgs; [ mergerfs ];
  boot.supportedFilesystems = [ "zfs" ];

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
      media = {
        type = "filesystem";
        device = "/mnt/media1:/mnt/media2:/mnt/media3";
        content = {
          type = "filesystem";
          format = "mergerfs";
          mountpoint = "/mnt/media";
          mountOptions = [
            "defaults"
            "noatime"
            "cache.files=off"
            "func.getattr=newest"
            "category.create=pfrd"
            "ignorepponrename=true"
          ];
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
        mountpoint = "/mnt/raid";
        datasets = { };
      };
    };
  };
}
