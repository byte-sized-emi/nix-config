{ lib, ... }:
{
  den.aspects.swayidle = {
    homeManager =
      {
        pkgs,
        config,
        ...
      }:
      {
        services.swayidle =
          let
            lockTimeout = 5 * 60; # 300 seconds
            suspendTimeout = 7 * 60; # 420 seconds
            screenOn = "${lib.getExe config.wayland.windowManager.niri.package} msg action power-on-monitors";
          in
          {
            enable = true;
            extraArgs = [ ];
            timeouts = [
              {
                timeout = lockTimeout - 15;
                command = "${lib.getExe pkgs.libnotify} -a 'swayidle' --urgency=critical --icon='system-lock-screen' 'Locking soon!'";
              }
              {
                timeout = lockTimeout;
                command = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
              }
              {
                timeout = suspendTimeout;
                command = "${lib.getExe' pkgs.systemd "systemctl"} suspend";
                resumeCommand = screenOn;
              }
            ];
            events = {
              before-sleep = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
              unlock = screenOn;
              after-resume = screenOn;
            };
          };
      };
  };
}
