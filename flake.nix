{
  description = "Top-Level configuration";

  inputs = {
    # NixOS official package source, using the nixos-24.11 branch here
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
    settings = {
      domain = "byte-sized.fyi";
      sso.domain = "sso.${specialArgs.settings.domain}";
    };
  };
  in
  {
    nixosConfigurations.nixnest = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = specialArgs;
      modules = [
        ./configuration.nix
        ./containers.nix
        ./spotify.nix
        ./kanidm.nix
        ./networking.nix

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
