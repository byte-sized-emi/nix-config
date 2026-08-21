{ __findFile, ... }:
{
  den.aspects.nixnest = {
    includes = [
      <audio>
      <auto-update>
      <cloudflared>
      <podman>
      <server-default>
      <service>
      <ssh-server>
      <stacks/atuin>
      <stacks/backups>
      <stacks/beeper>
      <stacks/control-server>
      <stacks/dawarich>
      <stacks/forgejo>
      <stacks/freshrss>
      <stacks/hedgedoc>
      <stacks/homeassistant>
      <stacks/immich>
      <stacks/linktree>
      <stacks/mealie>
      <stacks/media>
      <stacks/monitoring>
      <stacks/nix-serve>
      <stacks/ntfy>
      <stacks/renovate>
      <stacks/sso>
      <stacks/umami>
      <stacks/vaultwarden>
      <syncthing>
      <tailscale-server>
    ];

    nixos = { pkgs, ... }: {
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
      systemd.settings.Manager.RuntimeWatchdogSec = "30s";

      # Audio setup (service config lives in <audio>)
      services.pipewire.socketActivation = true;

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
    };
  };
}
