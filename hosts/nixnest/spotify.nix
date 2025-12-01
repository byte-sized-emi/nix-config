{ config, ... }:
let
  ZEROCONF_PORT = 10709;
in
{
  services.spotifyd = {
    enable = true;
    settings = {
      global = {
        device_name = config.networking.hostName;
        zeroconf_port = ZEROCONF_PORT;
        use_mpris = false;
        backend = "alsa";
        device = "sysdefault:CARD=sofhdadsp";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ ZEROCONF_PORT ];
}
