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
    flake.modules.nixos.ssh-server
    ./atuin.nix
    ./backups.nix
    ./beeper.nix
    ./certs.nix
    ./dawarich.nix
    ./forgejo.nix
    # ./homeassistant.nix
    ./immich.nix
    ./linktree.nix
    ./mealie.nix
    ./media.nix
    ./monitoring.nix
    ./networking
    ./nix-serve.nix
    ./ntfy.nix
    ./podman.nix
    ./renovate.nix
    ./settings.nix
    ./sso.nix
    ./umami.nix
    ./vaultwarden.nix
    inputs.quadlet-nix.nixosModules.quadlet
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nano
    wget
    git
    pciutils
    alsa-utils
  ];

  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vpl-gpu-rt # for newer GPUs on NixOS >24.05 or unstable
    ];
  };

  # May help if FFmpeg/VAAPI/QSV init fails (esp. on Arc with i915):
  # hardware.enableRedistributableFirmware = true;
  # boot.kernelParams = [ "i915.enable_guc=3" ];

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
