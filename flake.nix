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

    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";

    nixpkgs-unstable.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    niri.url = "github:sodiboo/niri-flake";
    vicinae.url = "github:vicinaehq/vicinae";
    slippi-launcher = {
      url = "github:byte-sized-emi/slippi-launcher-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      slippi-launcher,
      naersk,
      flake-utils,
      ...
    }@inputs:
    {
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
              {
                nixpkgs.overlays = [ self.overlays.x86_64-linux.default ];
              }
              (homeManagerConfig { extraModules = [ ./modules/home/graphical ]; })
              slippi-launcher.nixosModules.default
            ];
            specialArgs = {
              inherit inputs;
              pkgs-unstable = import nixpkgs-unstable {
                system = "x86_64-linux";
                config.allowUnfree = true;
              };
            };
          };

          nixnest = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
              settings = rec {
                domain = "byte-sized.fyi";
                home.domain = "home.${domain}";
                sso.domain = "sso.${domain}";
                meals.domain = "meals.${domain}";
                services.domain = "service.${domain}";
                git.domain = "git.${domain}";
                immich.domain = "images.${domain}";
                secrets.domain = "secrets.${domain}";
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
              {
                nixpkgs.overlays = [ self.overlays.x86_64-linux.default ];
              }
            ];
          };
        };
    }
    // (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
        };

        naersk' = pkgs.callPackage naersk { };
      in
      rec {
        formatter = pkgs.nixfmt-tree;
        packages.nix-update-server = naersk'.buildPackage {
          src = ./packages/nix-update-server/.;
          meta = {
            mainProgram = "nix-update-server";
          };
          nativeBuildInputs = with pkgs; [
            pkg-config
            makeWrapper
          ];
          buildInputs = with pkgs; [
            openssl
            git
            nixos-rebuild-ng
          ];
          postInstall = ''
            wrapProgram $out/bin/nix-update-server --prefix PATH : ${
              pkgs.lib.makeBinPath [
                pkgs.git
                pkgs.nixos-rebuild-ng
              ]
            }
          '';
        };
        overlays.default = final: prev: {
          nix-update-server = packages.nix-update-server;
        };
        devShells.default = pkgs.mkShell {
          inputsFrom = [ packages.nix-update-server ];
          buildInputs = with pkgs; [
            bacon
            rust-analyzer
            rustfmt
            rustc
          ];
        };

      }
    ));
}
