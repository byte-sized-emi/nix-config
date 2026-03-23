{
  flake,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./librelane.nix
    inputs.slippi-launcher.nixosModules.default
  ]
  ++ (with flake.modules.nixos; [
    default
    graphical
    syncthing
    auto-update
    # cachyos-kernel
  ]);

  environment.systemPackages = with pkgs; [
    uv
  ];

  environment.localBinInPath = true;

  services.xserver.videoDrivers = [ "modesetting" ];

  system.stateVersion = "25.05"; # Did you read the comment?
}
