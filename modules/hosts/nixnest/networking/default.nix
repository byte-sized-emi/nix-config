{
  den.aspects.nixnest.nixos = { config, ... }: {
    sops.secrets."cloudflared/tunnel".owner = config.users.users.cloudflared.name;

    # cloudflared (<cloudflared>) and tailscale-server (<tailscale-server>) are
    # included in the host aspect's `includes`.

    networking = {
      nameservers = [
        "100.100.100.100"
        "8.8.8.8"
        "1.1.1.1"
      ];

      search = [ "bushbaby-chimera.ts.net" ];

      # https://forgejo.org/docs/latest/admin/actions/runner-installation/#nixos
      # supposed to make cache actions work
      firewall.trustedInterfaces = [ "br-+" ];

      useDHCP = false;
      interfaces.enp2s0 = {
        ipv4.addresses = [
          {
            address = "192.168.0.201";
            prefixLength = 24;
          }
        ];
      };
      defaultGateway = "192.168.0.1";
    };

    # mDNS setup

    services.resolved.enable = true;

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
    # services.cloudflared = {
    services.my-cloudflared = {
      enable = true;
      tunnels.${config.settings.ingress_tunnel} = {
        credentialsFile = config.sops.secrets."cloudflared/tunnel".path;
        default = "http_status:404";
        originRequest = {
          matchSNItoHost = true;
          http2Origin = true;
        };
        # proxy everything to caddy (which will present a cloudflare origin cert for the external domains)
        ingress."*.${config.settings.domain}" = "https://localhost:443";
      };
    };
  };
}
