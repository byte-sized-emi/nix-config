{ __findFile, ... }:
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
      wayland.windowManager.niri.settings._children = [
        { spawn-at-startup = [ "zeditor" ]; }
        { spawn-at-startup = [ "todoist-electron" ]; }
        { spawn-at-startup = [ "obsidian" ]; }
        { spawn-at-startup = [ "thunderbird" ]; }

        { workspace = "browser"; }
        { workspace = "social"; }
        { workspace = "editor"; }
        { workspace = "extra"; }

        {
          window-rule = {
            _children = [
              { match._props.app-id = "^firefox$"; }
              { match._props.app-id = "^anki$"; }
              { open-on-workspace = "browser"; }
              { open-maximized = true; }
            ];
          };
        }
        {
          window-rule = {
            _children = [
              { match._props.app-id = "dev.zed.Zed"; }
              { match._props.app-id = "^obsidian$"; }
              { open-on-workspace = "editor"; }
              { open-maximized = true; }
            ];
          };
        }
        {
          window-rule = {
            _children = [
              { match._props.app-id = "^discord$"; }
              { match._props.app-id = "^signal$"; }
              { match._props.app-id = "^BeeperTexts$"; }
              { match._props.app-id = "^thunderbird$"; }
              { open-on-workspace = "social"; }
              { open-maximized = true; }
            ];
          };
        }
        {
          window-rule = {
            _children = [
              { match._props.app-id = "^deezer-enhanced$"; }
              { match._props.app-id = "^Todoist$"; }
              { open-on-workspace = "extra"; }
              { open-maximized = true; }
            ];
          };
        }
      ];
    };
  };
}
