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

  system.stateVersion = "25.11"; # Did you read the comment?
}
