{ inputs, lib, ... }:
{
  den.aspects.nixlaptop.nixos = { pkgs, ... }: {
    imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

    # secure boot config
    # keys in /var/lib/sbctl

    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl"; # generated with nix shell nixpkgs#sbctl -c sbctl create-keys
    };

    environment.systemPackages = with pkgs; [ sbctl ];

  };
}
