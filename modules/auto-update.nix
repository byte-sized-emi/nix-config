{ pkgs, lib, ... }:
let
  user = "nixupdate";
in
{
  users.users.${user} = {
    isSystemUser = true;
    description = "User to run the nix update server";
    createHome = false;
    group = user;
  };
  users.groups.${user} = { };

  environment.systemPackages = [ pkgs.nix-update-server ];
  systemd.services.update-daemon = {
    description = "Socket activated daemon to update the NixOS system based on a git branch";
    serviceConfig = {
      ExecStart = lib.getExe pkgs.nix-update-server;
      User = user;
    };
    after = [ "network.service" ];
  };

  systemd.sockets.update-daemon = {
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = "127.0.0.1:36196";
      Accept = false;
      # BindToDevice = "tailscale0";
    };
  };

  security.doas.extraRules = [
    {
      cmd = "nix-env";
      args = [ "switch" ];
      noPass = true;
      users = [ user ];
    }
  ];

  security.sudo.extraRules = [
    {
      users = [ user ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nix-env";
          options = [
            "NOPASSWD"
          ];
        }
      ];
    }
  ];

  programs.git.enable = true;
  programs.git.config.safe.directory = "/home/emilia/nix-config";
}
