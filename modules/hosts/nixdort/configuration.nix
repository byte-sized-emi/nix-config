{ __findFile, lib, ... }:
{
  den.aspects.nixdort = {
    includes = [
      <auto-update>
      <server-default>
      <ssh-server>
      <tailscale-server>
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
