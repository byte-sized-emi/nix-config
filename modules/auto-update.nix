{ pkgs, lib, ... }:
{
  environment.systemPackages = [ pkgs.nix-update-server ];
  systemd.services.update-daemon = {
    description = "Socket activated daemon to update the NixOS system based on a git branch";
    serviceConfig = {
      ExecStart = lib.getExe pkgs.nix-update-server;
      User = "root";
      WorkingDirectory = "/home/emilia/nix-config";
      AmbientCapabilities = "CAP_DAC_READ_SEARCH";
      ReadWriteDirectories = "/nix/store /etc/nixos /home/emilia/nix-config";
    };
    after = [ "network.service" ];
  };

  systemd.sockets.update-daemon = {
    wantedBy = [ "sockets.target" ];
    after = [ "tailscaled.service" ];
    socketConfig = {
      ListenStream = 36196;
      Accept = false;
      BindToDevice = "tailscale0";
    };
  };

  programs.git.enable = true;
  programs.git.config.safe.directory = "/home/emilia/nix-config";
}
