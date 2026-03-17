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
      icon = "notification";
    };
  };

  # to see the changes between current settings and nix settings:
  # nix shell nixpkgs#json-diff -c bash -c "json-diff <(jq -S . ~/.config/noctalia/settings.json) <(noctalia-shell ipc call state all | jq -S .settings)"

  programs.noctalia-shell = {
    enable = true;
    settings = {
      location.name = "Munich, Germany";
      colorSchemes.predefinedScheme = "Rose Pine";
      appLauncher = {
        enableClipboardHistory = true;
        enableClipPreview = false;
      };
      dock.enabled = false;
      notifications = {
        location = "bottom_right";
        lowUrgencyDuration = 2;
        normalUrgencyDuration = 4;
        criticalUrgencyDuration = 10;
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
              id = "SidePanelToggle";
              useDistroLogo = true;
            }
            {
              id = "ActiveWindow";
              maxWidth = 600;
              colorizeIcons = true;
            }
            {
              id = "LockKeys";
              showCapsLock = true;
              showNumLock = false;
              showScrollLock = false;
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
              id = "MediaMini";
            }
            {
              id = "plugin:tailscale";
            }
            {
              id = "Network";
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
        terminalCommand = "xdg-terminal";
        defaultPeerAction = "ssh";
      };
    };
  };
}
