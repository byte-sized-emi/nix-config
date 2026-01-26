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
    after = [
      "network.target"
      "tailscaled.service"
    ];
  };

  systemd.sockets.update-daemon = {
    wantedBy = [ "sockets.target" ];
    after = [
      "network.target"
      "tailscaled.service"
    ];
    listenStreams = [ "36196" ];
    socketConfig = {
      BindToDevice = "tailscale0";
      ExecStartPre = pkgs.writeShellScript "wait-for-tailscale" ''
        shopt -s expand_aliases
        alias sleep=${lib.getExe' pkgs.coreutils "sleep"}
        alias ip=${lib.getExe' pkgs.iproute2 "ip"}
        alias grep=${lib.getExe pkgs.gnugrep}

        echo Waiting for tailscale0 to get an IP address...
        for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
          if ip addr show dev tailscale0 | grep -q 'inet '; then break; fi
          echo $i
          sleep 1
        done
      '';
    };
  };

  programs.git.enable = true;
  programs.git.config.safe.directory = "/home/emilia/nix-config";
}
