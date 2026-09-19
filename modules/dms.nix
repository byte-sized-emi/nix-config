{ inputs, lib, ... }:
{
  den.aspects.dms = {
    homeManager = { pkgs, ... }: {
      imports = [ inputs.dms.homeModules.dank-material-shell ];

      xdg.configFile."DankMaterialShell/themes/catppuccin/theme.json".source =
        ./dms/themes/catppuccin/theme.json;

      programs.dank-material-shell = {
        enable = true;
        systemd.enable = true;

        settings = {
          currentThemeName = "custom";
          currentThemeCategory = "registry";
          customThemeFile = "/home/emilia/.config/DankMaterialShell/themes/catppuccin/theme.json";
          registryThemeVariants = {
            catppuccin.dark = {
              flavor = "mocha";
              accent = "flamingo";
            };
          };
          cornerRadius = 12;
          controlCenterShowMicPercent = true;
          showWorkspacePadding = true;
          appIdSubstitutions = [ ];
          cursorSettings = {
            theme = "System Default";
            size = 24;
            niri = {
              hideWhenTyping = false;
              hideAfterInactiveMs = 0;
            };
            hyprland = {
              hideOnKeyPress = false;
              hideOnTouch = false;
              inactiveTimeout = 0;
            };
            mango.cursorHideTimeout = 0;
          };
          acProfileName = "1";
          batteryProfileName = "0";
          batteryNotifyLow = true;
          batteryAutoPowerSaver = true;
          notificationTimeoutCritical = 30000;
          notificationCompactMode = true;
          notificationShowTimeoutBar = true;
          notificationHistoryMaxAgeDays = 3;
          notificationOverlayEnabled = true;
          osdPowerProfileEnabled = true;
          updaterIntervalSeconds = 86400;
          barConfigs = [
            {
              id = "default";
              name = "Main Bar";
              enabled = true;
              position = 0;
              screenPreferences = [ "all" ];
              showOnLastDisplay = true;
              leftWidgets = [
                {
                  id = "keyboard_layout_name";
                  enabled = true;
                }
                "weather"
                {
                  id = "runningApps";
                  enabled = true;
                  runningAppsCompactMode = true;
                  runningAppsGroupByApp = false;
                  runningAppsCurrentWorkspace = true;
                  runningAppsCurrentMonitor = false;
                }
                "focusedWindow"
              ];
              centerWidgets = [
                "workspaceSwitcher"
                "music"
              ];
              rightWidgets = [
                "systemTray"
                "cpuUsage"
                "memUsage"
                "battery"
                "notificationButton"
                "clock"
                "controlCenterButton"
              ];
              spacing = 4;
              innerPadding = 0;
              barInsetPadding = -1;
              bottomGap = 0;
              transparency = 1;
              widgetTransparency = 1;
              squareCorners = false;
              noBackground = false;
              maximizeWidgetIcons = false;
              maximizeWidgetText = false;
              removeWidgetPadding = false;
              widgetPadding = 8;
              gothCornersEnabled = false;
              gothCornerRadiusOverride = false;
              gothCornerRadiusValue = 12;
              borderEnabled = false;
              borderColor = "surfaceText";
              borderOpacity = 1;
              borderThickness = 1;
              widgetOutlineEnabled = false;
              widgetOutlineColor = "primary";
              widgetOutlineOpacity = 1;
              widgetOutlineThickness = 1;
              fontScale = 1;
              iconScale = 1;
              autoHide = false;
              autoHideStrict = false;
              autoHideDelay = 250;
              showOnWindowsOpen = false;
              openOnOverview = false;
              visible = true;
              popupGapsAuto = true;
              popupGapsManual = 4;
              maximizeDetection = true;
              useOverlayLayer = false;
              scrollEnabled = true;
              scrollXBehavior = "column";
              scrollYBehavior = "workspace";
              shadowIntensity = 0;
              shadowOpacity = 60;
              shadowColorMode = "default";
              shadowCustomColor = "#000000";
              clickThrough = false;
              hoverPopouts = false;
              hoverPopoutDelay = 150;
              attachToScreenEdge = true;
              island = false;
            }
          ];
          desktopClockCustomColor = {
            r = 1;
            g = 1;
            b = 1;
            a = 1;
            hsvHue = -1;
            hsvSaturation = 0;
            hsvValue = 1;
            hslHue = -1;
            hslSaturation = 0;
            hslLightness = 1;
            valid = true;
          };
          systemMonitorCustomColor = {
            r = 1;
            g = 1;
            b = 1;
            a = 1;
            hsvHue = -1;
            hsvSaturation = 0;
            hsvValue = 1;
            hslHue = -1;
            hslSaturation = 0;
            hslLightness = 1;
            valid = true;
          };
          builtInPluginSettings = {
            dms_settings_search.trigger = "?";
            dms_clipboard_search.trigger = "cb";
            dms_power.trigger = "pw";
            dms_qr_generator.trigger = "qrg";
          };
          configVersion = 18;
        };
      };

      wayland.windowManager.niri.settings = {
        binds = {
          "XF86AudioPlay".spawn = [
            "${lib.getExe pkgs.dms-shell}"
            "ipc"
            "call"
            "mpris"
            "playPause"
          ];
          "XF86AudioNext".spawn = [
            "${lib.getExe pkgs.dms-shell}"
            "ipc"
            "call"
            "mpris"
            "next"
          ];
          "XF86AudioPrev".spawn = [
            "${lib.getExe pkgs.dms-shell}"
            "ipc"
            "call"
            "mpris"
            "previous"
          ];
          "XF86MonBrightnessUp".spawn = [
            "${lib.getExe pkgs.dms-shell}"
            "ipc"
            "call"
            "brightness"
            "increment"
            "5"
            ""
          ];
          "XF86MonBrightnessDown".spawn = [
            "${lib.getExe pkgs.dms-shell}"
            "ipc"
            "call"
            "brightness"
            "decrement"
            "5"
            ""
          ];
          "Mod+L".spawn = [
            "${lib.getExe pkgs.dms-shell}"
            "ipc"
            "call"
            "lock"
            "lockAndOutputsOff"
          ];
          "Mod+N".spawn = [
            "${lib.getExe pkgs.dms-shell}"
            "ipc"
            "call"
            "notifications"
            "toggle"
          ];
          "Mod+Shift+N".spawn = [
            "${lib.getExe pkgs.dms-shell}"
            "ipc"
            "call"
            "notifications"
            "clearAll"
          ];
          "Mod+B".spawn = [
            "${lib.getExe pkgs.dms-shell}"
            "ipc"
            "call"
            "notifications"
            "toggleDoNotDisturb"
          ];
          # TODO:
          # "KP_Add".spawn = "${lib.getExe pkgs.dms-shell} ipc";
          # "KP_Subtract".spawn = "${lib.getExe pkgs.dms-shell} ipc";
          # "KP_enter".spawn = "${lib.getExe pkgs.dms-shell} ipc";
        };
        switch-events.lid-close.spawn = [
          "${lib.getExe pkgs.dms-shell}"
          "ipc"
          "call"
          "lock"
          "lockAndOutputsOff"
        ];
      };

      services.swayidle.events.lock = "${lib.getExe pkgs.dms-shell} ipc call lock lock";

      xdg.desktopEntries = {
        caffeine = {
          name = "Toggle idle / sleep inhibitor";
          exec = "${lib.getExe pkgs.dms-shell} ipc call inhibit toggle";
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
    };
  };
}
