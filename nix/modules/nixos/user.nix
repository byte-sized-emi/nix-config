{ pkgs, config, ... }:
{
  users.groups.emilia = { };
  users.users.emilia = {
    isNormalUser = true;
    group = config.users.groups.emilia.name;
    extraGroups = [
      "wheel"
      "podman"
      "docker"
      "audio"
      "networkmanager"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      tree
      kanidm_1_8
      cloudflared
      bind
    ];
  };

  home-manager.backupFileExtension = "bac";

  console.keyMap = "de";

  time.timeZone = "Europe/Berlin";

  security.doas.enable = true;
  security.doas.extraRules = [
    {
      users = [ config.users.users.emilia.name ];
      keepEnv = true;
      persist = true;
    }
  ];

  security = {
    polkit = {
      enable = true;
      # allow me to use systemd without password every time
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" && subject.user == "emilia") {
            return polkit.Result.YES;
          }
        });
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.policykit.exec" && subject.user == "emilia") {
            return polkit.Result.AUTH_ADMIN_KEEP;
          }
        });
      '';
    };
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    wget
    pulseaudio
    pciutils
    alsa-utils
    nano
  ];
}
