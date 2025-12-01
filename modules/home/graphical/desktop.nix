{ inputs, pkgs, ... }:
{
  # import the home manager module
  imports = [
    inputs.noctalia.homeModules.default
    inputs.niri.homeModules.niri
  ];

  programs.kitty.enable = true;

  programs.niri = {
    settings = {
      environment = {
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
      };
      spawn-at-startup = [
        {
          command = [ "noctalia-shell" ];
        }
        {
          command = [
            "vicinae"
            "server"
          ];
        }
        # TODO: Tailscale
      ];
      workspaces = {
        "1-browser".name = "browser";
        "2-social".name = "social";
      };
      window-rules = [
        {
          matches = [
            { app-id = "^firefox$"; }
          ];
          open-on-workspace = "browser";
        }
        {
          matches = [
            { app-id = "^discord$"; }
          ];
          open-on-workspace = "social";
        }
      ];
      binds =
        let
          noctalia-action =
            cmd:
            [
              "noctalia-shell"
              "ipc"
              "call"
            ]
            ++ (pkgs.lib.splitString " " cmd);
          noctalia-hidden = cmd: {
            action.spawn = noctalia-action cmd;
            hotkey-overlay.hidden = true;
          };
        in
        {
          "XF86AudioRaiseVolume" = noctalia-hidden "volume increase";
          "XF86AudioLowerVolume" = noctalia-hidden "volume decrease";
          "XF86AudioMute" = noctalia-hidden "volume muteOutput";
          "XF86AudioMicMute" = noctalia-hidden "volume muteInput";
          "XF86AudioPlay" = noctalia-hidden "media playPause";
          "XF86AudioNext" = noctalia-hidden "media next";
          "XF86AudioPrev" = noctalia-hidden "media previous";
          "XF86MonBrightnessUp" = noctalia-hidden "brightness increase";
          "XF86MonBrightnessDown" = noctalia-hidden "brightness decrease";
          "Alt+Space" = {
            action.spawn = [
              "vicinae"
              "toggle"
            ];
          };
          "Mod+O" = {
            action.toggle-overview = [ ];
          };
          "Mod+Q" = {
            action.close-window = [ ];
          };
          "Alt+F4" = {
            action.close-window = [ ];
          };
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
    };
  };

  programs.noctalia-shell = {
    enable = true;
    settings = {
      # configure noctalia here; defaults will
      # be deep merged with these attributes.
      # dock = {
      # };
      location = {
        name = "Munich, Germany";
      };
      bar = {
        density = "compact";
        position = "top";
        showCapsule = false;
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
              id = "NotificationHistory";
            }
            {
              id = "Battery";
              alwaysShowPercentage = true;
              warningThreshold = 30;
            }
            {
              id = "Clock";
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
        };
      };
    };
  };
}
