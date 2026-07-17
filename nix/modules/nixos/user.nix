{ pkgs, config, ... }:
{
  users.groups.emilia = { };
  users.groups.keys = { };
  users.users.emilia = {
    isNormalUser = true;
    group = config.users.groups.emilia.name;
    extraGroups = [
      "wheel"
      "podman"
      "docker"
      "audio"
      "networkmanager"
      "dialout"
      "keys"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      tree
      kanidm_1_10 # also update hosts/nixnest/sso.nix
      bind
    ];
    # this is only the initial password, I change this on every host. Don't @ me.
    initialHashedPassword = "$y$j9T$07XdSvsI38i10SFC4x9.u.$QrlTjcpGUYAxWOAfX9vkz75hNnARHgkTLxO5R8.znZA";
  };

  environment.pathsToLink = [ "/share/zsh" ];

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
    pulseaudio
    wget
    nano
  ];
}
