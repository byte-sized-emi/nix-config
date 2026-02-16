{ hostName, ... }:
{
  imports = [
    ./boot.nix
    ./user.nix
    ./nixConfig.nix
    ./controller.nix
    ./secrets.nix
    ./networking.nix
  ];

  networking.hostName = hostName;
}
