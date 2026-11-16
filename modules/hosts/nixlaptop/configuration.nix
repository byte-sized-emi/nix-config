{ __findFile, ... }:
{
  den.aspects.nixlaptop = {
    includes = [
      <auto-update>
      <auto-update/desktop>
      <fachschaft>
      <graphical>
      <vpn>
      <syncthing>
      # <cache-beacon>
    ];

    nixos = { lib, pkgs, ... }: {
      networking.networkmanager.dispatcherScripts = [
        {
          source = pkgs.writeText "wifi-bahn-autologin" ''
            if [ "$2" != "up" ]; then
                exit
            fi

            WIFI_NAME=$(${pkgs.networkmanager}/bin/nmcli -f 802-11-wireless.ssid con show $CONNECTION_UUID | cut -c22- | ${lib.getExe pkgs.gawk} '{$1=$1};1')
            logger "Device $DEVICE_IFACE coming up. Connected to $WIFI_NAME"

            if [ "$WIFI_NAME" == "WIFI@DB" ]; then
                logger "WIFI@DB detected. Running CNA logon!"
                ${lib.getExe pkgs.curlWithGnuTls} --connect-to wifi.bahn.de:443:10.101.8.121:443 'https://wifi.bahn.de/cna/logon' -H 'sec-ch-ua-platform: "Linux"' -H 'X-Csrf-Token: csrf' -H 'Referer: https://wifi.bahn.de/cna/' -H 'Content-type: application/json' --data-raw '{}'
                exit
            elif [ "$WIFI_NAME" == "DBLounge" ]; then
                logger "DB Lounge WiFi detected. Running logon!"
                ${lib.getExe pkgs.curlWithGnuTls} --connect-to wifi.bahn.de:443:185.109.152.241:443 'https://wifi.bahn.de/login' -H 'Content-Type: application/x-www-form-urlencoded' --data-raw 'login=oneclick'
                exit
            elif [ "$WIFI_NAME" == "KEOLIS Nederland" ]; then
                logger "Keoliss WiFi detected. Running CNA"
                ${lib.getExe pkgs.curlWithGnuTls} --connect-to www.ombord.info:443:10.101.0.1:443 'https://www.ombord.info/hotspot/hotspot.cgi?method=login&url=https%3A%2F%2Fkeolisnederland.on.icomera.com%2F%3Fsuccess%3Dtrue%26correlationId%3Da7a6c1ae-08f0-4fb7-97a7-2055dd1551c2&onerror=https%3A%2F%2Fkeolisnederland.on.icomera.com%2F%3Ferror%3Dtrue%26correlationId%3Da7a6c1ae-08f0-4fb7-97a7-2055dd1551c2' -H 'Referer: https://keolisnederland.on.icomera.com/'
                exit
            elif [ "$WIFI_NAME" == "OEBB" ]; then
                logger "ÖBB WiFi detected. Asking politely in Austrian!"
                ${lib.getExe pkgs.curlWithGnuTls} --connect-to railnet.oebb.at:443:172.19.5.2:443 'https://railnet.oebb.at/en/connecttoweb' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://railnet.oebb.at' --data-raw '_token=SVlTuLVs9GQmlQW7xfg0w9OqsRKLyWqYSgndjx63&_ceid=1245&checkit=on&form_type=registration'
                exit
            elif [ "$WIFI_NAME" == "_SNCF_WIFI_INOUI" ]; then
                logger "Smelling stinky bread; bypassing..."
                ${lib.getExe pkgs.curlWithGnuTls} 'https://wifi.sncf/router/api/connection/activate/auto' -H 'content-type: application/json' --data-raw '{"without21NetConnection":false}'
                exit
            elif [ "$WIFI_NAME" == "WIFIonICE" ]; then
                logger "WIFIonICE detected. "
                ${lib.getExe pkgs.curlWithGnuTls} https://login.wifionice.de/auth_register_online -H 'Content-Type: application/x-www-form-urlencoded' --data-raw 'enc_url=&tncs=true'
                exit
            elif [ "$WIFI_NAME" == "DSB_Wi-Fi" ]; then
                ${lib.getExe pkgs.curlWithGnuTls} 'https://dsbwifi.dk/login.php' --data-raw 'language=dk'
                exit
            elif [ "$WIFI_NAME" == "CDWiFi" ]; then
                ${lib.getExe pkgs.curlWithGnuTls} --insecure 'https://cdwifi.cz/portal/api/vehicle/gateway/user/authenticate?category=internet&url=https%3A%2F%2Fcdwifi.cz%2Fportal%2Fapi%2Fvehicle%2Fgateway%2Fuser%2Fsuccess&onerror=https%3A%2F%2Fcdwifi.cz%2Fportal%2Fapi%2Fvehicle%2Fgateway%2Fuser%2Ferror'
                exit
            else
                logger "Connected to \"$WIFI_NAME\", not any db wifi. Ignoring..."
            fi
          '';
          type = "basic";
        }
      ];

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
          # intel-compute-runtime
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
