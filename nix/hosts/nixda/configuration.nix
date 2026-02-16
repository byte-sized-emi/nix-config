{
  flake,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.slippi-launcher.nixosModules.default
  ]
  ++ (with flake.modules.nixos; [
    default
    graphical
    syncthing
    auto-update
  ]);

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = false;

  system.stateVersion = "25.11"; # Did you read the comment?
}
