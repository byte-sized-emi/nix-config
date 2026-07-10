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
    # inputs.slippi-launcher.nixosModules.default
    inputs.lanzaboote.nixosModules.lanzaboote
  ]
  ++ (with flake.modules.nixos; [
    default
    graphical
    syncthing
    auto-update
    vpn
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
    enable = false;
    openFirewall = true;
  };

  services.gns3-server = {
    enable = false;
    vpcs.enable = true;
    dynamips.enable = true;
    ubridge.enable = true;
  };

  environment.systemPackages = with pkgs; [
    uv
    sbctl # secure boot
    gns3-gui
    inetutils
    eduvpn-client
  ];

  environment.localBinInPath = true;

  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
      # intel-vaapi-driver # For older processors. LIBVA_DRIVER_NAME=i965
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
