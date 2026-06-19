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
    flake.modules.nixos.tailscale-server
    flake.modules.nixos.auto-update
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  networking.hostId = "e8c8c66c";

  environment.systemPackages = with pkgs; [
    git
    nano
    wget
    mergerfs
  ];

  system.stateVersion = "26.11";
}
