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
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  environment.systemPackages = with pkgs; [
    git
    nano
    wget
    mergerfs
  ];

  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.emilia.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOkbGLfWyjFJQxJY8pDodBG4r567LoOT9gzPFnx5rBx8"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINVLqQSi5EhE8NPWcYjtolf4F6m/L/wjjmO2jf3W0ozL emilia@fedora-pc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIopGi9F4+v4lckvFcEv5PmoxKknS3nESZ7jeKFkIoCq emilia@fedora-laptop"
  ];

  system.stateVersion = "26.11";
}
