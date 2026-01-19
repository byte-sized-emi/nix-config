{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  # import the home manager module
  imports = [
    inputs.niri.homeModules.niri
  ];

  programs.alacritty.enable = true;

  home.packages = with pkgs; [
    xwayland-satellite
    wl-mirror
    jq
    kdePackages.kwallet
    kdePackages.kwallet-pam
    # gnome-keyring
    # xdg-desktop-portal-gtk
    # xdg-desktop-portal-gnome
    # polkit-kde-agent
    kdePackages.polkit-kde-agent-1
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
        debug.honor-xdg-activation-with-invalid-serial = [ ];
        spawn-at-startup = [
          {
            sh = "QS_ICON_THEME=\"Adwaita\" ${lib.getExe config.programs.noctalia-shell.package}";
          }
          {
            # to unblock bluetooth on startup - for some reason neither niri nor quickshell
            # does this automatically
            command = [
              "rfkill"
              "unblock"
              "bluetooth"
            ];
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
          { command = [ "todoist-electron" ]; }
          { command = [ "obsidian" ]; }
          { command = [ "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init" ]; }
          {
            sh = "signal-desktop --password-store=\"kwallet6\"";
          }
          { command = [ "beeper" ]; }
        ];
        workspaces = {
          "1-browser".name = "browser";
          "2-social".name = "social";
          "3-editor".name = "editor";
          "4-extra".name = "extra";
        };
        window-rules = [
          # TODO: Add window rule here to block out screencasts:
          # https://github.com/YaLTeR/niri/wiki/Screencasting
          {
            matches = [
              { is-window-cast-target = true; }
            ];
            focus-ring = {
              active.color = "#f38ba8";
              inactive.color = "#7d0d2d";
            };
            border.inactive.color = "#7d0d2d";
            shadow.color = "#7d0d2d70";
            tab-indicator = {
              active.color = "#f38ba8";
              inactive.color = "#7d0d2d";
            };
          }
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
              { app-id = "^obsidian$"; }
            ];
            open-on-workspace = "editor";
            open-maximized = true;
          }
          {
            matches = [
              { app-id = "^discord$"; }
              { app-id = "^signal$"; }
              { app-id = "^BeeperTexts$"; }
            ];
            open-on-workspace = "social";
            open-maximized = true;
          }
          {
            matches = [
              { app-id = "^deezer-enhanced$"; }
              { app-id = "^Todoist$"; }
            ];
            open-on-workspace = "extra";
            open-maximized = true;
          }
        ];
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
          # I have no idea why this workaround is necessary.
          "Mod+F" = action-with-arg "spawn" [
            "niri"
            "msg"
            "action"
            "maximize-window-to-edges"
          ];
          "Mod+Shift+F" = action "fullscreen-window";
          "Mod+P" = {
            repeat = false;
            action.spawn-sh = "wl-mirror $(niri msg --json focused-output | jq -r .name)";
          };
          # "Mod+M" = action "maximize-column";
          "Mod+L" = noctalia-action "sessionMenu lockAndSuspend";
          "Mod+V" = noctalia-action "launcher clipboard";
          "Mod+Shift+S" = action "screenshot";
          "Mod+Left" = action "focus-column-left";
          "Mod+Right" = action "focus-column-right";
          "Mod+Shift+Left" = action "move-column-left";
          "Mod+Shift+Right" = action "move-column-right";
          "Mod+Shift+Up" = action "move-window-to-workspace-up";
          "Mod+Shift+Down" = action "move-window-to-workspace-down";
          "Mod+Ctrl+Left" = action "move-window-to-monitor-left";
          "Mod+Ctrl+Right" = action "move-window-to-monitor-right";
          "Mod+Up" = action "focus-workspace-up";
          "Mod+Down" = action "focus-workspace-down";
          "Mod+1" = action-with-arg "focus-workspace" "browser";
          "Mod+2" = action-with-arg "focus-workspace" "social";
          "Mod+3" = action-with-arg "focus-workspace" "editor";
          "Mod+4" = action-with-arg "focus-workspace" "extra";
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
}
