{
  lib,
  pkgs,
  config,
  ...
}:
{
  services.swayidle =
    let
      lockTimeout = 5 * 60; # 300 seconds
      suspendTimeout = 15 * 60; # 900 seconds
      noctalia-ipc = "${lib.getExe config.programs.noctalia-shell.package} ipc call";

      screenOn = "${lib.getExe config.programs.niri.package} msg action power-on-monitors";
    in
    {
      enable = true;
      extraArgs = [ ];
      timeouts = [
        {
          timeout = lockTimeout - 5;
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
      events = [
        {
          event = "before-sleep";
          command = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
        }
        {
          event = "lock";
          command = "${noctalia-ipc} lockScreen lock";
        }
        {
          event = "unlock";
          command = screenOn;
        }
        {
          event = "after-resume";
          command = screenOn;
        }
      ];
    };
}
