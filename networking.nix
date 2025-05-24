{ config, settings, ... }:

{
  networking.hostName = "nixnest";
  networking.nameservers = [ "100.100.100.100" "8.8.8.8" "1.1.1.1" ];
  networking.search = [ "bushbaby-chimera.ts.net" ];

  # mDNS setup

  services.resolved = {
    enable = true;
    extraConfig = "MulticastDNS=yes";
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Open ports in the firewall.
  networking.firewall.allowedUDPPorts = [
    5355 # mDNS using systemd-resolved / LLMNR
  ];

  users.groups.cloudflared = {};
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };

  # systemd service name: cloudflared-tunnel-b68b3740-8dc9-4136-aa64-bf1ed77d4886
  services.cloudflared = {
    enable = true;
    tunnels."b68b3740-8dc9-4136-aa64-bf1ed77d4886" = {
      credentialsFile = "/var/cloudflare-creds/b68b3740-8dc9-4136-aa64-bf1ed77d4886.json";
      default = "http_status:404";
      originRequest.originServerName = settings.sso.domain;
      ingress = {
        "sso.byte-sized.fyi" = "https://localhost:8443";
      };
    };
  };

  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--ssh" ];
    authKeyFile = "/var/tailscale/auth_key";
  };
}
