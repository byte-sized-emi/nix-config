{
  description = "Top-Level configuration";

  inputs = {
    # NixOS official package source, using the nixos-25.05 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quadlet-nix = {
      url = "github:SEIAROTg/quadlet-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, vscode-server, quadlet-nix, ... }@inputs:
  let specialArgs = {
    inputs = inputs;
    settings = {
      domain = "byte-sized.fyi";
      sso.domain = "sso.${specialArgs.settings.domain}";
      services.domain = "service.${specialArgs.settings.domain}";
      dawarich.enable = true;
    };
  };
  in
  {
    nixosConfigurations.nixnest = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = specialArgs;
      modules = [
        ./configuration.nix
        ./podman.nix
        ./hass.nix
        ./dawarich.nix
        ./spotify.nix
        ./sso.nix
        ./networking.nix
        ./monitoring.nix

        home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.emi = import ./home.nix;
          }

        vscode-server.nixosModules.default
        ({ config, pkgs, ... }: {
          services.vscode-server.enable = true;
        })

        quadlet-nix.nixosModules.quadlet
      ];
    };
  };
}
