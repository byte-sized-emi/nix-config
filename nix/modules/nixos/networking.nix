{
  hostName,
  pkgs,
  ...
}:
{
  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };

  networking.networkmanager.enable = true;
  networking.hostName = hostName;
}
