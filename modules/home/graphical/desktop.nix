{ inputs, pkgs, ... }:
{
  # import the home manager module
  imports = [
    inputs.noctalia.homeModules.default
    inputs.niri.homeModules.niri
  ];

  programs.alacritty.enable = true;

  home.packages = with pkgs; [
    xwayland-satellite
    # gnome-keyring
    # xdg-desktop-portal-gtk
    # xdg-desktop-portal-gnome
    # polkit-kde-agent
  ];

  # https://github.com/sodiboo/niri-flake/blob/main/docs.md
  programs.niri =
    let
      noctalia-ipc-call =
        cmd:
        [
          "noctalia-shell"
          "ipc"
          "call"
        ]
        ++ (pkgs.lib.splitString " " cmd);
      noctalia-action = cmd: {
        action.spawn = noctalia-ipc-call cmd;
      };
      noctalia-action-hidden = cmd: {
        action.spawn = noctalia-ipc-call cmd;
        hotkey-overlay.hidden = true;
      };
      noctalia-action-locked = cmd: {
        action.spawn = noctalia-ipc-call cmd;
        allow-when-locked = true;
      };
      action-with-arg = actionName: arg: {
        action.${actionName} = arg;
      };
      action = actionName: action-with-arg actionName [ ];
    in
    {
      settings = {
        environment = {
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
        };
        prefer-no-csd = true;
        spawn-at-startup = [
          {
            sh = "QS_ICON_THEME=\"Adwaita\" noctalia-shell";
          }
          {
            command = [
              "vicinae"
              "server"
            ];
          }
          { command = [ "discord" ]; }
          { command = [ "firefox" ]; }
          { command = [ "zeditor" ]; }
        ];
        workspaces = {
          "1-browser".name = "browser";
          "2-editor".name = "editor";
          "3-social".name = "social";
          "4-music".name = "music";
        };
        window-rules = [
          {
            matches = [
              { app-id = "^firefox$"; }
            ];
            open-on-workspace = "browser";
            open-maximized = true;
          }
          {
            matches = [
              { app-id = "dev.zed.Zed"; }
            ];
            open-on-workspace = "editor";
            open-maximized = true;
          }
          {
            matches = [
              { app-id = "^discord$"; }
              { app-id = "^signal$"; }
            ];
            open-on-workspace = "social";
            open-maximized = true;
          }
          {
            matches = [
              { app-id = "^deezer-enhanced$"; }
            ];
            open-on-workspace = "music";
            open-maximized = true;
          }
        ];
        binds = {
          "XF86AudioRaiseVolume" = noctalia-action-locked "volume increase";
          "XF86AudioLowerVolume" = noctalia-action-locked "volume decrease";
          "XF86AudioMute" = noctalia-action-locked "volume muteOutput";
          "XF86AudioMicMute" = noctalia-action-locked "volume muteInput";
          "XF86AudioPlay" = noctalia-action-hidden "media playPause";
          "XF86AudioNext" = noctalia-action-hidden "media next";
          "XF86AudioPrev" = noctalia-action-hidden "media previous";
          "XF86MonBrightnessUp" = noctalia-action-locked "brightness increase";
          "XF86MonBrightnessDown" = noctalia-action-locked "brightness decrease";
          "Alt+Space" = action-with-arg "spawn" [
            "vicinae"
            "toggle"
          ];
          "Mod+O" = action "toggle-overview";
          "Mod+Q" = action "close-window";
          "Mod+H" = action "show-hotkey-overlay";
          # I have no idea why this workaround is necessary.
          "Mod+M" = action-with-arg "spawn" [
            "niri"
            "msg"
            "action"
            "maximize-window-to-edges"
          ];
          # "Mod+M" = action "maximize-column";
          "Mod+Shift+M" = action "fullscreen-window";
          "Mod+L" = noctalia-action "sessionMenu lockAndSuspend";
          "Mod+V" = noctalia-action "launcher clipboard";
          "Mod+Shift+S" = action "screenshot";
          "Mod+Left" = action "focus-column-left";
          "Mod+Right" = action "focus-column-right";
          "Ctrl+Shift+Left" = action "move-column-left";
          "Ctrl+Shift+Right" = action "move-column-right";
          "Mod+Shift+Left" = action "move-window-to-monitor-left";
          "Mod+Shift+Right" = action "move-window-to-monitor-right";
          "Mod+Up" = action "focus-workspace-up";
          "Mod+Down" = action "focus-workspace-down";
          "Ctrl+Shift+Up" = action "move-window-to-workspace-up";
          "Ctrl+Shift+Down" = action "move-window-to-workspace-down";
          "Mod+1" = action-with-arg "focus-workspace" "browser";
          "Mod+2" = action-with-arg "focus-workspace" "editor";
          "Mod+3" = action-with-arg "focus-workspace" "social";
          "Mod+4" = action-with-arg "focus-workspace" "music";
          "Mod+5" = action-with-arg "focus-workspace" 5;
          "Mod+6" = action-with-arg "focus-workspace" 6;
          "Mod+7" = action-with-arg "focus-workspace" 7;
          "Mod+8" = action-with-arg "focus-workspace" 8;
          "Mod+9" = action-with-arg "focus-workspace" 9;
          "Alt+F4" = action "close-window";
          "Ctrl+Alt+T" = action-with-arg "spawn" "alacritty";
        };
        input = {
          keyboard = {
            xkb = {
              layout = "de";
            };
          };
          touchpad = {
            tap = true;
            dwt = true;
            dwtp = true;
            natural-scroll = true;
            accel-profile = "flat";
            click-method = "clickfinger";
          };
          focus-follows-mouse = {
            enable = true;
            max-scroll-amount = "10%";
          };
          warp-mouse-to-focus.enable = true;
          workspace-auto-back-and-forth = false;
        };
        switch-events = {
          lid-close = noctalia-action "sessionMenu lockAndSuspend";
        };
      };
    };

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
            }
          ];
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";
            }
          ];
          right = [
            {
              id = "MediaMini";
            }
            {
              id = "WiFi";
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
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
            {
              id = "NotificationHistory";
            }
          ];
        };
      };
    };
  };
}
