{ config, lib, pkgs, settings, inputs, ... }:

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

  users.users.emilia.openssh.authorizedKeys.keys = [
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
    dates = "Fri 10:00";
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

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = let users = config.users.users; groups = config.users.groups; in {
      "tailscale/auth_key".owner = "root";
      "borg/backupKey" = {
        owner = users.borg.name;
        group = groups.borg.name;
      };
      "cloudflared/tunnel".owner = users.cloudflared.name;
      "caddy/secretsEnv".owner = users.caddy.name;
      "forgejo/actionsRunnerToken" = {
        owner = users.forgejo.name;
        group = groups.forgejo.name;
      };
      "immich/envFile".owner = "root";
      "kanidm/tlsChain".owner = users.kanidm.name;
      "kanidm/tlsKey".owner = users.kanidm.name;
      "kanidm/tailscaleOauthSecret".owner = users.kanidm.name;
      "kanidm/forgejoOauthSecret".owner = users.kanidm.name;
      "kanidm/mealieOauthSecret".owner = users.kanidm.name;
      "kanidm/immichOauthSecret".owner = users.kanidm.name;
      "kanidm/mealieOauthSecretEnv".owner = "root";
    };
  };

  system.stateVersion = "24.11"; # Did you read the comment?
}
