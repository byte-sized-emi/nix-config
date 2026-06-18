{
  pkgs,
  inputs,
  flake,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    flake.modules.nixos.default
    flake.modules.nixos.ssh-server
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  environment.systemPackages = with pkgs; [
    git
    nano
    wget
    mergerfs
  ];

  system.stateVersion = "26.11";
}
