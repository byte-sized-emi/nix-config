{ config, ... }:
{
  sops.secrets."tailscale/auth_key" = { };

  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--ssh"
      "--advertise-exit-node"
      "--advertise-tags=tag:server"
    ];
    authKeyFile = config.sops.secrets."tailscale/auth_key".path;
    useRoutingFeatures = "server";
    openFirewall = true;
  };
}
