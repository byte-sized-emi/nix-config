{ config, ... }:
{
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
}
