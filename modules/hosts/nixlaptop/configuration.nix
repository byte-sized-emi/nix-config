{
  inputs,
  lib,
  __findFile,
  ...
}:
{
  den.aspects.nixlaptop = {
    includes = [
      <auto-update>
      <fachschaft>
      <graphical>
      <vpn>
      <syncthing>
      # <cache-beacon>
    ];

    nixos = { pkgs, ... }: {
      networking.networkmanager.wifi.powersave = true;

      programs.ausweisapp = {
        enable = false;
        openFirewall = true;
      };

      services.gns3-server = {
        enable = false;
        vpcs.enable = true;
        dynamips.enable = true;
        ubridge.enable = true;
      };

      environment.systemPackages = with pkgs; [
        uv
        gns3-gui
        inetutils
        eduvpn-client
      ];

      environment.localBinInPath = true;

      services.xserver.videoDrivers = [ "modesetting" ];

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
          # intel-vaapi-driver # For older processors. LIBVA_DRIVER_NAME=i965
        ];
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "iHD";
      };

      system.stateVersion = "25.05"; # Did you read the comment?
    };

    provides.to-users.homeManager = {
      programs.niri.settings.spawn-at-startup = [
        { command = [ "zeditor" ]; }
        { command = [ "todoist-electron" ]; }
        { command = [ "obsidian" ]; }
        { command = [ "thunderbird" ]; }
      ];
    };
  };
}
