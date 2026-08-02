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
    flake.modules.nixos.server-default
    # flake.modules.nixos.cache-beacon
    ./atuin.nix
    ./backups.nix
    ./beeper.nix
    ./certs.nix
    ./data.nix
    ./dawarich.nix
    ./forgejo.nix
    ./hedgedoc.nix
    ./homeassistant.nix
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

  hardware.enableRedistributableFirmware = true;

  # Cap the CPU at C6 to avoid the deep C-state (C8/C10) hard-hang on this N150
  # mini PC. See https://bugs.launchpad.net/bugs/2160711
  boot.kernelParams = [ "intel_idle.max_cstate=2" ];

  # Hardware watchdog: auto-reboot if the box hangs (best-effort on C10 hangs).
  boot.kernelModules = [ "iTCO_wdt" ];
  systemd.extraConfig = "RuntimeWatchdogSec=30";

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
