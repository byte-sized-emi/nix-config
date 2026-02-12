{ inputs, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia-shell = {
    enable = true;
    settings = {
      location = {
        name = "Munich, Germany";
      };
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
              id = "WiFi";
            }
            {
              id = "VPN";
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
              displayMode = "alwaysShow";
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
  };
}
