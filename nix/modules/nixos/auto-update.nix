{
  pkgs,
  lib,
  perSystem,
  ...
}:
let
  nix-update-server = perSystem.self.nix-update-server;
in
{
  environment.systemPackages = [ nix-update-server ];
  systemd.services.update-daemon = {
    description = "Socket activated daemon to update the NixOS system based on a git branch";
    restartIfChanged = false;
    serviceConfig = {
      ExecStart = lib.getExe nix-update-server;
      User = "root";
      WorkingDirectory = "/home/emilia/nix-config";
      AmbientCapabilities = "CAP_DAC_READ_SEARCH";
      ReadWriteDirectories = "/nix/store /etc/nixos /home/emilia/nix-config";
    };
    after = [
      "network.target"
      "tailscaled.service"
    ];
  };

  systemd.sockets.update-daemon = {
    wantedBy = [
      "sockets.target"
      "multi-user.target"
    ];
    after = [
      "network.target"
      "tailscaled.service"
    ];
    listenStreams = [ "36196" ];
    socketConfig = {
      BindToDevice = "tailscale0";
      ExecStartPre = "${lib.getExe pkgs.tailscale} wait --timeout=30s";
    };
  };

  programs.git.enable = true;
  programs.git.config.safe.directory = "/home/emilia/nix-config";
}
