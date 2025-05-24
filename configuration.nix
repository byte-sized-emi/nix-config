{ config, lib, pkgs, settings, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "de";
    useXkbConfig = true; # use xkb.options in tty.
  };

  users.users.emi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "podman" "audio" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      tree
      kanidm
      openssl
      cloudflared
    ];
  };

  programs.zsh.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nano
    wget
    git
    pulseaudio
    pciutils
    alsa-utils
  ];

  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.emi.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOkbGLfWyjFJQxJY8pDodBG4r567LoOT9gzPFnx5rBx8"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINVLqQSi5EhE8NPWcYjtolf4F6m/L/wjjmO2jf3W0ozL emilia@fedora-pc"
  ];

  # Audio setup
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    socketActivation = true;
  };

  systemd.user.services.wireplumber.wantedBy = [ "default.target" ];
  systemd.user.services.pipewire.wantedBy = [ "default.target" ];
  users.users.emi.linger = true;

  system.stateVersion = "24.11"; # Did you read the comment?
}
