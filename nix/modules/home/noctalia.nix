{ inputs, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  xdg.desktopEntries = {
    caffeine = {
      name = "Toggle idle / sleep inhibitor";
      exec = "noctalia-shell ipc call idleInhibitor toggle";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "caffeine";
    };

    clear-notification = {
      name = "Clear Notifications";
      comment = "Clear all noctalia notifications";
      exec = "noctalia-shell ipc call notifications clear";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "notification-disabled";
    };

    toggle-notifications = {
      name = "Toggle Notifications";
      comment = "Toggles noctalia notifications / do not disturb mode";
      exec = "noctalia-shell ipc call notifications toggleDND";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "bell";
    };
  };

  # to see the changes between current settings and nix settings:
  # nix shell nixpkgs#json-diff -c bash -c "json-diff <(jq -S . ~/.config/noctalia/settings.json) <(noctalia-shell ipc call state all | jq -S .settings)"

  programs.noctalia-shell = {
    enable = true;
    settings = {
      location = {
        name = "Munich, Germany";
        firstDayOfWeek = 0;
      };
      colorSchemes.predefinedScheme = "Rose Pine";
      appLauncher = {
        enableClipboardHistory = false;
        enableClipPreview = false;
      };
      noctaliaPerformance = {
        disableWallpaper = true;
        disableDesktopWidgets = true;
      };
      sessionMenu = {
        countdownDuration = 3000;
      };
      dock.enabled = false;
      notifications = {
        location = "bottom_right";
        lowUrgencyDuration = 2;
        normalUrgencyDuration = 4;
        criticalUrgencyDuration = 10;
        enableMarkdown = true;
        saveToHistory = {
          low = false;
          normal = true;
          critical = true;
        };
      };
      bar = {
        density = "compact";
        position = "top";
        showCapsule = true;
        widgets = {
          left = [
            {
              id = "plugin:catwalk";
            }
            {
              id = "MediaMini";
            }
            {
              id = "SidePanelToggle";
              useDistroLogo = true;
            }
            {
              id = "LockKeys";
              showCapsLock = true;
              showNumLock = false;
              showScrollLock = false;
            }
            {
              id = "ActiveWindow";
              maxWidth = 300;
              colorizeIcons = true;
            }
          ];
          center = [
            {
              id = "Workspace";
              labelMode = "none";
              hideUnoccupied = true;
            }
            {
              id = "Taskbar";
            }
          ];
          right = [
            {
              id = "Tray";
              drawerEnabled = false;
            }
            {
              id = "plugin:tailscale";
            }
            {
              id = "Network";
              iconColor = "primary";
              textColor = "none";
            }
            {
              id = "Bluetooth";
            }
            {
              id = "Microphone";
            }
            {
              id = "Volume";
              displayMode = "alwaysShow";
            }
            {
              id = "Battery";
              alwaysShowPercentage = true;
              warningThreshold = 30;
              displayMode = "icon-always";
              showNoctaliaPerformance = true;
              showPowerProfiles = true;
            }
            {
              id = "KeepAwake";
            }
            {
              id = "Clock";
              formatHorizontal = "HH:mm d. MMM";
              formatVertical = "HH mm";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
            {
              id = "NotificationHistory";
            }
            {
              id = "ControlCenter";
            }
          ];
        };
      };
    };
    plugins = {
      sources = [
        {
          enabled = true;
          name = "Official Noctalia Plugins";
          url = "https://github.com/noctalia-dev/noctalia-plugins";
        }
      ];
      states = {
        catwalk = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        tailscale = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        polkit-agent = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
      };
      version = 2;
    };

    pluginSettings = {
      catwalk = {
        minimumThreshold = 25;
        hideBackground = true;
      };
      tailscale = {
        showIpAddress = false;
        compactMode = true;
        pingCount = 3;
        refreshInterval = 10000;
        terminalCommand = "xdg-terminal";
        defaultPeerAction = "ssh";
      };
    };
  };
}
