{ inputs, ... }:
{
  den.aspects.auto-update.packages = { pkgs, ... }: {
    nix-update-server =
      let
        naersk' = pkgs.callPackage inputs.naersk { };
        pname = "nix-update-server";
      in
      naersk'.buildPackage {
        src = ./nix-update-server;
        meta = {
          mainProgram = pname;
        };
        nativeBuildInputs = with pkgs; [
          pkg-config
          makeWrapper
        ];
        buildInputs = with pkgs; [
          openssl
          git
          nixos-rebuild
        ];
        postInstall = ''
          wrapProgram $out/bin/${pname} --prefix PATH : ${
            pkgs.lib.makeBinPath [
              pkgs.git
              pkgs.nixos-rebuild
            ]
          }
        '';
      };
  };
}
