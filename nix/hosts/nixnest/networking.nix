{
  config,
  pkgs,
  ...
}:
{
  networking.nameservers = [
    "100.100.100.100"
    "8.8.8.8"
    "1.1.1.1"
  ];
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

  users.groups.cloudflared = { };
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };

  # created using:
  # $ cloudflared tunnel login
  # $ cloudflared tunnel create <tunnel-name>
  # systemd service name: cloudflared-tunnel-${settings.ingress_tunnel}
  services.cloudflared = {
    enable = true;
    tunnels.${config.settings.ingress_tunnel} = {
      credentialsFile = config.sops.secrets."cloudflared/tunnel".path;
      default = "http_status:404";
      originRequest.originServerName = config.settings.sso.domain;
      ingress = { }; # defined in the individual services
    };
  };

  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--ssh"
      "--advertise-exit-node"
    ];
    authKeyFile = config.sops.secrets."tailscale/auth_key".path;
    useRoutingFeatures = "server";
    openFirewall = true;
  };

  # reverse proxy setup is done where it is needed
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v0.2.2"
      ];
      hash = "sha256-SrAHzXhaT3XO3jypulUvlVHq8oiLVYmH3ibh3W3aXAs=";
    };
    environmentFile = config.sops.secrets."caddy/secretsEnv".path;
    globalConfig = ''
      acme_dns cloudflare {env.CF_API_TOKEN}
      dns cloudflare {env.CF_API_TOKEN}
    '';
    virtualHosts."(abort_external)".extraConfig = ''
      @external not remote_ip private_ranges 100.64.0/10 fd7a:115c:a1e0::/48
      abort @external
    '';
  };
}
