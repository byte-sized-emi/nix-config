{
  pkgs,
  inputs,
  flake,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    flake.modules.nixos.default
    flake.modules.nixos.ssh-server
    flake.modules.nixos.tailscale-server
    flake.modules.nixos.auto-update
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./node-exporter.nix
  ];

  networking.hostId = "e8c8c66c";

  # sudo nix run github:nix-community/nixos-anywhere -- --flake '.#nixdort' --target-host nixos@192.168.0.226 --extra-files ./tmp --disk-encryption-keys /var/lib/luks/key ./luks-key --phases kexec,disko,install

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

  services.nfs.server = {
    enable = true;
    exports = ''
      /mnt/media 100.64.0.0/10(rw,sync,fsid=0,no_subtree_check) fd7a:115c:a1e0::/48(rw,sync,fsid=0,no_subtree_check)
    '';
  };

  users.users.media = {
    uid = 311;
    group = "media";
  };

  users.groups.media = {
    gid = 311;
    members = [
      "media"
      "emilia"
    ];
  };

  # TODO:
  # - monotoring, esp. for ZFS / the disks
  # - smartd

  system.stateVersion = "26.11";
}
