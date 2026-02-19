{
  pkgs,
  inputs,
  flake,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    flake.modules.nixos.default
    flake.modules.nixos.syncthing
    flake.modules.nixos.auto-update
    flake.modules.nixos.service
    ./settings.nix
    ./podman.nix
    ./hass.nix
    ./dawarich.nix
    ./sso.nix
    ./networking.nix
    ./monitoring.nix
    ./git.nix
    ./food.nix
    ./immich.nix
    ./backups.nix
    ./secrets.nix
    ./vaultwarden.nix
    ./homepage.nix
    ./beeper.nix
    ./nix-serve.nix
    ./umami.nix
    inputs.vscode-server.nixosModules.default
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

  services.vscode-server.enable = true;

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

  # automatic upgrade
  # Upgrade log can be seen using:
  # `systemctl status nixos-upgrade.service`
  system.autoUpgrade = {
    enable = false;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "Mon,Fri 10:00";
    randomizedDelaySec = "45min";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "monthly" ];
  };

  nix.gc = {
    automatic = true;
    dates = "Fri 12:00";
    randomizedDelaySec = "15min";
    options = "--delete-older-than 30d"; # Delete generations older than 30 days
  };

  system.stateVersion = "24.11"; # Did you read the comment?
}
