{
  pkgs,
  ...
}:
{
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
  };

  # this should be done on a per-device scale, instead of here.
  # the servers shouldn't need networkmanager.
  networking.networkmanager.enable = true;
}
