{
  config,
  flake,
  ...
}:
{
  imports = [
    flake.modules.nixos.my-cloudflared
    ./tailscale.nix
    ./caddy.nix
  ];

  networking.nameservers = [
    "100.100.100.100"
    "8.8.8.8"
    "1.1.1.1"
  ];
  networking.search = [ "bushbaby-chimera.ts.net" ];

  # https://forgejo.org/docs/latest/admin/actions/runner-installation/#nixos
  # supposed to make cache actions work
  networking.firewall.trustedInterfaces = [ "br-+" ];

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
      ingress = { }; # defined in the individual services
    };
  };
}
