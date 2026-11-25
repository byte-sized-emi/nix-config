{ den, lib, ... }:
{
  den.aspects.nixdort = {
    includes = [
      den.aspects.auto-update
      den.aspects.server-default
      den.aspects.ssh-server
      den.aspects.tailscale-server
    ];

    nixos = { pkgs, ... }: {
      networking.hostId = "e8c8c66c";

      environment.systemPackages = with pkgs; [
        git
        nano
        wget
        efibootmgr
      ];

      boot.loader.systemd-boot.enable = lib.mkForce false;
      boot.loader.grub = {
        enable = true;
        efiSupport = true;
        configurationLimit = 7;
      };

      system.stateVersion = "26.11";
    };
  };
}
