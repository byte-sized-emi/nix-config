{
  hostName,
  flake,
  pkgs-unstable,
  ...
}:
{
  imports = [
    flake.modules.nixos.nixpkgs-unstable
  ];

  services.tailscale = {
    enable = true;
    package = pkgs-unstable.tailscale;
  };
  networking.networkmanager.enable = true;
  networking.hostName = hostName;
}
