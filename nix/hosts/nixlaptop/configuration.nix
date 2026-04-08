{
  flake,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./librelane.nix
    inputs.slippi-launcher.nixosModules.default
    inputs.lanzaboote.nixosModules.lanzaboote
  ]
  ++ (with flake.modules.nixos; [
    default
    graphical
    syncthing
    auto-update
    # cachyos-kernel
  ]);

  # secure boot config
  # keys in /var/lib/sbctl

  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl"; # generated with nix shell nixpkgs#sbctl -c sbctl create-keys
  };

  networking.networkmanager.wifi.powersave = true;

  programs.ausweisapp = {
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    uv
    sbctl # secure boot
  ];

  environment.localBinInPath = true;

  services.xserver.videoDrivers = [ "modesetting" ];

  system.stateVersion = "25.05"; # Did you read the comment?
}
