{
  pkgs,
  inputs,
  flake,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    flake.modules.nixos.auto-update
    flake.modules.nixos.default
    flake.modules.nixos.service
    flake.modules.nixos.syncthing
    ./backups.nix
    ./beeper.nix
    ./dawarich.nix
    ./food.nix
    ./git.nix
    ./hass.nix
    ./homepage.nix
    ./immich.nix
    ./linktree.nix
    ./media.nix
    ./monitoring.nix
    ./networking.nix
    ./nix-serve.nix
    ./ntfy.nix
    ./podman.nix
    ./renovate.nix
    ./secrets.nix
    ./settings.nix
    ./sso.nix
    ./umami.nix
    ./vaultwarden.nix
    inputs.quadlet-nix.nixosModules.quadlet
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nano
    wget
    git
    pulseaudio
    pciutils
    alsa-utils
    speedtest-cli
  ];

  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.emilia.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOkbGLfWyjFJQxJY8pDodBG4r567LoOT9gzPFnx5rBx8"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINVLqQSi5EhE8NPWcYjtolf4F6m/L/wjjmO2jf3W0ozL emilia@fedora-pc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIopGi9F4+v4lckvFcEv5PmoxKknS3nESZ7jeKFkIoCq emilia@fedora-laptop"
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
  users.users.emilia.linger = true;

  # NOTE: for garbage collecting old EFI entries, use:
  # `sudo nix-env -p /nix/var/nix/profiles/system --list-generations`
  # to list generations

  nix.optimise = {
    automatic = true;
    dates = [ "monthly" ];
  };

  nix.gc = {
    automatic = true;
    dates = "Fri 12:00";
    randomizedDelaySec = "15min";
    options = "--delete-older-than 10d"; # Delete generations older than 10 days
  };

  system.stateVersion = "24.11"; # Did you read the comment?
}
