{ lib, ... }:
{
  # dummy, REPLACE LATER

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/b921831e-d34b-4b85-8e33-92f4c0ea10c6";
    fsType = "ext4";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
