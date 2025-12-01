{
  description = "Top-Level configuration";

  inputs = {
    # NixOS official package source, using the nixos-25.05 branch here
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-25.11";
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quadlet-nix = {
      url = "github:SEIAROTg/quadlet-nix";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-unstable.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    niri.url = "github:sodiboo/niri-flake";
    vicinae.url = "github:vicinaehq/vicinae";
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
      nixosConfigurations =
        let
          homeManagerConfig =
            {
              extraModules ? [ ],
            }:
            {
              imports = [ home-manager.nixosModules.home-manager ];
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };

              home-manager.users.emilia = {
                imports = [ ./modules/home/common ] ++ extraModules;
              };
            };
        in
        {
          nixlaptop = nixpkgs.lib.nixosSystem {
            modules = [
              ./hosts/nixlaptop
              (homeManagerConfig { extraModules = [ ./modules/home/graphical ]; })
              (
                { pkgs, ... }:
                {
                  nixpkgs.overlays = [
                    (final: prev: {
                      slippi-launcher = import ./packages/slippi.nix { inherit pkgs; };
                    })
                  ];
                }
              )
            ];
            specialArgs = { inherit inputs; };
          };

          nixnest = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
              settings = rec {
                domain = "byte-sized.fyi";
                sso.domain = "sso.${domain}";
                meals.domain = "meals.${domain}";
                services.domain = "service.${domain}";
                git.domain = "git.${domain}";
                immich.domain = "images.${domain}";
                dawarich.enable = true;
                ingress_tunnel = "a7cff2a8-b287-4edc-94fd-35527c3c3858";
                backup.interval = "Mon,Fri 02:00";
                backup.prepare.interval = "Mon,Fri 01:20";
                backup.prepare.interval_cron = "20 1 * * 1,5";
              };
            };
            modules = [
              ./hosts/nixnest
              (homeManagerConfig { })
            ];
          };
        };
    };
}
