{ __findFile, ... }:
{
  den.aspects.graphical = {
    includes = [
      <apps/browser>
      <apps/email>
      <apps/rclone>
      <apps/signal>
      <apps/steam>
      <apps/vicinae>
      <apps/zed>
      <audio>
      <controller>
      <docker>
      <fonts>
      <niri>
      <noctalia>
      <swayidle>
      (<den/unfree> [
        "discord"
        "discord-unwrapped"
        "beeper"
        "obsidian"
        "todoist-electron"
      ])
    ];

    nixos = { pkgs, ... }: {
      networking.networkmanager.enable = true;

      # programs.slippi-launcher = {
      #   enable = false;
      #   enableAppImageSupport = true;
      # };

      services.displayManager.ly = {
        enable = true;
        x11Support = false;
        settings = {
          # animation = "matrix";
          animation = "dur_file";
          dur_file_path = "${./blackhole-smooth-240x67.dur}";
          bigclock = "en";
          clear_password = true;
          show_tty = true;
          full_color = true;
          text_in_center = true;
          default_input = "password";
          clock = "%a %b %d.%m.%Y %H:%M:%S";
        };
      };

      i18n.defaultLocale = "en_US.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = "de_DE.UTF-8";
        LC_IDENTIFICATION = "de_DE.UTF-8";
        LC_MEASUREMENT = "de_DE.UTF-8";
        LC_MONETARY = "de_DE.UTF-8";
        LC_NAME = "de_DE.UTF-8";
        LC_NUMERIC = "de_DE.UTF-8";
        LC_PAPER = "de_DE.UTF-8";
        LC_TELEPHONE = "de_DE.UTF-8";
        LC_TIME = "de_DE.UTF-8";
      };

      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            # Shows battery charge of connected devices on supported
            # Bluetooth adapters. Defaults to 'false'.
            Experimental = true;
          };
          Policy = {
            # Enable all controllers when they are found. This includes
            # adapters present on start as well as adapters that are plugged
            # in later on. Defaults to 'true'.
            AutoEnable = true;
          };
        };
      };

      # printing
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

      services.printing = {
        enable = true;
        drivers = with pkgs; [
          cups-filters
          cups-browsed
          gutenprint
        ];
      };

      services.ipp-usb.enable = true;

      # Configure keymap in X11
      services.xserver.xkb = {
        layout = "de";
        variant = "";
      };
    };

    homeManager = { pkgs, ... }: {
      # programs.zsh.shellAliases.sudo = lib.mkForce "pkexec --keep-cwd";

      # ls /run/current-system/sw/share/applications # for global packages
      # ls /etc/profiles/per-user/$(id -n -u)/share/applications # for user packages
      # ls ~/.nix-profile/share/applications # for home-manager packages

      xdg.desktopEntries.nix-config = {
        name = "Nix config (git.byte-sized.fyi)";
        comment = "My nix/NixOS config";
        exec = "xdg-open https://git.byte-sized.fyi/emilia/nix-config";
        terminal = false;
        type = "Application";
        categories = [ "Network" ];
        icon = "nix-snowflake";
      };

      # so stealing stuff from lucas gets even easier
      xdg.desktopEntries.keyruu-shinyflakes = {
        name = "Keyruu shinyflakes nix config";
        exec = "xdg-open https://github.com/keyruu/shinyflakes";
        comment = "Lucas / Keyruu shinyflakes repo";
        terminal = false;
        type = "Application";
        categories = [ "Network" ];
        icon = "nix-snowflake";
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "firefox.desktop";
          "application/pdf" = "com.github.xournalpp.xournalpp.desktop";
          "application/x-xoj" = "com.github.xournalpp.xournalpp.desktop";
          "application/x-xojpp" = "com.github.xournalpp.xournalpp.desktop";
          "application/x-xopp" = "com.github.xournalpp.xournalpp.desktop";
          "application/x-xopt" = "com.github.xournalpp.xournalpp.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/about" = "firefox.desktop";
          "x-scheme-handler/unknown" = "firefox.desktop";
        };
      };

      home.packages = with pkgs; [
        kdePackages.kate
        kdePackages.filelight
        discord
        obsidian
        # spotify
        signal-desktop
        todoist-electron
        xournalpp
        wev
        element-desktop
        vlc
        libreoffice
        file
        jellyflix
        plezy
        deezer-enhanced
        mission-center
        beeper
      ];
    };
  };
}
