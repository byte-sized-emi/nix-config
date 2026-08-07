{ __findFile, lib, ... }:
{
  den.aspects.emilia = { host, ... }: {
    includes = [
      (<den/user-shell> "zsh")
      <apps/git>
      <apps/shell>
    ]
    ++ lib.optionals (host.hostName == "nixlaptop") [
      <ai>
      <graphical>
      <anki>
      <fachschaft>
    ]
    ++ lib.optionals (host.hostName == "nixda") [
      <graphical>
    ];

    nixos = { config, pkgs, ... }: {
      users.groups.emilia = { };
      users.groups.keys = { };
      users.users.emilia = {
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
        # this is only the initial password, I change this on every host. Don't @ me.
        initialHashedPassword = "$y$j9T$07XdSvsI38i10SFC4x9.u.$QrlTjcpGUYAxWOAfX9vkz75hNnARHgkTLxO5R8.znZA";
      };

      environment.pathsToLink = [ "/share/zsh" ];
      environment.systemPackages = with pkgs; [ nano ];

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
    };

    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        tree
        bind
        pulseaudio
        wget
        openssl
        htop
        btop
        bottom
        age
        sops
        nixd
        nil
        usbutils
        borgbackup
        wl-clipboard-rs
        kanidm_1_10
      ];

      programs.home-manager.enable = true;

      home.stateVersion = "24.11";
    };
  };
}
