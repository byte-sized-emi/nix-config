{ lib, ... }:
{
  den.aspects.niri = {
    nixos = { pkgs, ... }: {
      programs.niri.enable = true;

      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;

      services.gnome.gnome-keyring.enable = false;
      security.pam.services.login.kwallet.enable = true;

      xdg.portal.extraPortals = [
        pkgs.kdePackages.kwallet
      ];
    };

    homeManager =
      {
        pkgs,
        config,
        ...
      }:
      {
        programs.alacritty.enable = true;

        home.packages = with pkgs; [
          xwayland-satellite
          wl-mirror
          jq
          kdePackages.kwallet
          kdePackages.kwallet-pam
          papirus-icon-theme
          kdePackages.dolphin
          kdePackages.okular
          kdePackages.ark
          kdePackages.breeze
        ];

        home.pointerCursor = {
          enable = true;
          name = "Capitaine";
          package = pkgs.capitaine-cursors;
          gtk.enable = true;
        };

        gtk = {
          enable = true;
          iconTheme = {
            name = "Papirus";
            package = pkgs.papirus-icon-theme;
          };
          cursorTheme = {
            name = "Capitaine";
            package = pkgs.capitaine-cursors;
          };
        };

        wayland.windowManager.niri =
          let
            noctalia-ipc-call =
              cmd:
              [
                (lib.getExe config.programs.noctalia-shell.package)
                "ipc"
                "call"
              ]
              ++ (lib.splitString " " cmd);
            noctalia-action = cmd: {
              spawn = noctalia-ipc-call cmd;
            };
            noctalia-action-hidden = cmd: {
              _props.hotkey-overlay-title = null;
              spawn = noctalia-ipc-call cmd;
            };
            noctalia-action-locked = cmd: {
              _props.allow-when-locked = true;
              spawn = noctalia-ipc-call cmd;
            };
            action-with-arg = actionName: arg: {
              ${actionName} = arg;
            };
            action = actionName: {
              ${actionName} = { };
            };
          in
          {
            enable = true;
            package = pkgs.niri;
            settings = {
              cursor = {
                xcursor-theme = "breeze_cursors";
                xcursor-size = 26;
              };
              environment = {
                ELECTRON_OZONE_PLATFORM_HINT = "auto";
              };
              prefer-no-csd = { };
              debug = {
                honor-xdg-activation-with-invalid-serial = { };
              };
              layout = {
                gaps = 8;
                tab-indicator = {
                  place-within-column = { };
                  length = {
                    _props.total-proportion = 0.8;
                  };
                };
              };
              input = {
                keyboard.xkb.layout = "de";
                touchpad = {
                  tap = { };
                  dwt = { };
                  dwtp = { };
                  natural-scroll = { };
                  accel-profile = "flat";
                  click-method = "clickfinger";
                };
                focus-follows-mouse = {
                  _props.max-scroll-amount = "10%";
                };
                warp-mouse-to-focus = { };
                workspace-auto-back-and-forth = false;
              };
              binds = {
                "XF86AudioRaiseVolume" = action-with-arg "spawn" [
                  "pactl"
                  "set-sink-volume"
                  "@DEFAULT_SINK@"
                  "+5%"
                ];
                "XF86AudioLowerVolume" = action-with-arg "spawn" [
                  "pactl"
                  "set-sink-volume"
                  "@DEFAULT_SINK@"
                  "-5%"
                ];
                "XF86AudioMute" = action-with-arg "spawn" [
                  "pactl"
                  "set-sink-mute"
                  "@DEFAULT_SINK@"
                  "toggle"
                ];
                "XF86AudioMicMute" = action-with-arg "spawn" [
                  "pactl"
                  "set-source-mute"
                  "@DEFAULT_SOURCE@"
                  "toggle"
                ];
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
                "Mod+M" = action "maximize-column";

                # https://github.com/sodiboo/niri-flake/pull/1382
                # "Mod+F" = action-with-arg "spawn" [
                #   "niri"
                #   "msg"
                #   "action"
                #   "maximize-window-to-edges"
                # ];
                "Mod+Shift+F" = action "fullscreen-window";
                "Mod+P" = {
                  _props.repeat = false;
                  spawn-sh = "wl-mirror $(niri msg --json focused-output | jq -r .name)";
                };
                # "Mod+M" = action "maximize-column";
                "Mod+L" = noctalia-action "sessionMenu lockAndSuspend";
                "Mod+V" = noctalia-action "launcher clipboard";
                "Mod+Shift+S" = action "screenshot";
                "Mod+Left" = action "focus-column-or-monitor-left";
                "Mod+Right" = action "focus-column-or-monitor-right";
                "Mod+Shift+Left" = action "move-column-left";
                "Mod+Shift+Right" = action "move-column-right";
                "Mod+Shift+Up" = action "move-column-to-workspace-up";
                "Mod+Shift+Down" = action "move-column-to-workspace-down";
                "Mod+Ctrl+Left" = action "move-column-to-monitor-left";
                "Mod+Ctrl+Right" = action "move-column-to-monitor-right";
                "Mod+Up" = action "focus-window-or-workspace-up";
                "Mod+Down" = action "focus-window-or-workspace-down";

                # keypad bindings
                "KP_Up" = action "focus-window-or-workspace-up";
                "KP_Down" = action "focus-window-or-workspace-down";
                "KP_Left" = action "focus-column-left";
                "KP_Right" = action "focus-column-right";
                "KP_Begin" = action "toggle-overview"; # under the 5 key
                "KP_Add" = noctalia-action "notifications toggleHistory";
                "KP_Subtract" = noctalia-action "notifications clear";
                "KP_enter" = noctalia-action "notifications toggleDND";

                "Mod+1" = action-with-arg "focus-workspace" 1;
                "Mod+2" = action-with-arg "focus-workspace" 2;
                "Mod+3" = action-with-arg "focus-workspace" 3;
                "Mod+4" = action-with-arg "focus-workspace" 4;
                "Mod+5" = action-with-arg "focus-workspace" 5;
                "Mod+6" = action-with-arg "focus-workspace" 6;
                "Mod+7" = action-with-arg "focus-workspace" 7;
                "Mod+8" = action-with-arg "focus-workspace" 8;
                "Mod+9" = action-with-arg "focus-workspace" 9;
                "Alt+F4" = action "close-window";
                "Ctrl+Alt+T" = action-with-arg "spawn" "alacritty";

                "Mod+R" = action "switch-preset-column-width";
                "Mod+Shift+R" = action "switch-preset-column-width-back";
                "Mod+T" = action "toggle-column-tabbed-display";
                # practically "Mod+BracketLeft"/"Mod+BracketRight" but for german keyboard
                # "Mod+Shift+8" = action "consume-or-expel-window-left";
                # "Mod+Shift+9" = action "consume-or-expel-window-right";
                # these both go to the right!
                "Mod+Comma" = action "consume-window-into-column";
                "Mod+Shift+Comma" = action "expel-window-from-column";
                "Mod+Minus" = action-with-arg "set-column-width" "-10%";
                "Mod+Plus" = action-with-arg "set-column-width" "+10%";
              };
              switch-events = {
                lid-close = noctalia-action "sessionMenu lockAndSuspend";
              };

              # repeated top-level nodes: workspaces, spawns and window rules
              _children = [
                {
                  spawn-sh-at-startup = "QS_ICON_THEME=\"Papirus\" QT_QPA_PLATFORMTHEME=gtk3 ${lib.getExe config.programs.noctalia-shell.package}";
                }
                # to unblock bluetooth on startup - for some reason neither niri nor quickshell
                # does this automatically
                {
                  spawn-at-startup = [
                    "rfkill"
                    "unblock"
                    "bluetooth"
                  ];
                }
                {
                  spawn-at-startup = [
                    "vicinae"
                    "server"
                  ];
                }
                { spawn-at-startup = [ "firefox" ]; }
                { spawn-at-startup = [ "discord" ]; }
                { spawn-at-startup = [ "beeper" ]; }
                { spawn-at-startup = [ "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init" ]; }

                # TODO: Add window rule here to block out screencasts:
                # https://github.com/YaLTeR/niri/wiki/Screencasting
                {
                  window-rule = {
                    _children = [
                      { match._props.is-window-cast-target = true; }
                      {
                        focus-ring = {
                          active-color = "#f38ba8";
                          inactive-color = "#7d0d2d";
                        };
                      }
                      {
                        border = {
                          inactive-color = "#7d0d2d";
                        };
                      }
                      {
                        shadow = {
                          color = "#7d0d2d70";
                        };
                      }
                      {
                        tab-indicator = {
                          active-color = "#f38ba8";
                          inactive-color = "#7d0d2d";
                        };
                      }
                    ];
                  };
                }
              ];
            };
          };
      };
  };
}
