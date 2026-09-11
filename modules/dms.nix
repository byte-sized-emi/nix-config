{ inputs, lib, ... }:
{
  den.aspects.dms = {
    homeManager = { pkgs, ... }: {
      imports = [ inputs.dms.homeModules.dank-material-shell ];

      programs.dank-material-shell = {
        enable = true;
        systemd.enable = true;
      };

      wayland.windowManager.niri.settings = {
        binds = {
          "XF86AudioPlay".spawn = [ "${lib.getExe pkgs.dms-shell}"  "ipc" "call" "mpris" "playPause" ];
          "XF86AudioNext".spawn = [ "${lib.getExe pkgs.dms-shell}" "ipc" "call" "mpris" "next" ];
          "XF86AudioPrev".spawn = [ "${lib.getExe pkgs.dms-shell}" "ipc" "call" "mpris" "previous" ];
          "XF86MonBrightnessUp".spawn = [ "${lib.getExe pkgs.dms-shell}" "ipc" "call" "brightness" "increment" "5" ];
          "XF86MonBrightnessDown".spawn = [ "${lib.getExe pkgs.dms-shell}" "ipc" "call" "brightness" "decrement" "5" ];
          "Mod+L".spawn = [ "${lib.getExe pkgs.dms-shell}" "ipc" "call" "lock" "lockAndOutputsOff" ];
          # TODO:
          # "KP_Add".spawn = "${lib.getExe pkgs.dms-shell} ipc";
          # "KP_Subtract".spawn = "${lib.getExe pkgs.dms-shell} ipc";
          # "KP_enter".spawn = "${lib.getExe pkgs.dms-shell} ipc";
        };
        switch-events.lid-close.spawn = [ "${lib.getExe pkgs.dms-shell}" "ipc" "call" "lock" "lockAndOutputsOff" ];
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
