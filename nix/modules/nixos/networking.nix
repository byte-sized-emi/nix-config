{ hostName, ... }:
{
  services.tailscale.enable = true;
  networking.networkmanager.enable = true;
  networking.hostName = hostName;
}
