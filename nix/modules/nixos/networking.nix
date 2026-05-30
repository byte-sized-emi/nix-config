{
  hostName,
  pkgs,
  ...
}:
{
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
  };

  networking.networkmanager.enable = true;
  networking.hostName = hostName;
}
