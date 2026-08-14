{ inputs, ... }:
{
  den.aspects.control-server = {
    devShells = { pkgs, ... }: {
      control-server = pkgs.mkShell {
        nativeBuildInputs = with pkgs.buildPackages; [
          bacon
          rust-analyzer
          rustfmt
          rustc
          clippy
          cargo
          pkg-config
          openssl
        ];
      };
    };
    packages = { pkgs, ... }: {
      control-server =
        let
          naersk' = pkgs.callPackage inputs.naersk { };
          pname = "control-server";
        in
        naersk'.buildPackage {
          src = ./control-server;
          meta = {
            mainProgram = pname;
          };
          nativeBuildInputs = with pkgs; [
            pkg-config
            makeWrapper
          ];
          buildInputs = with pkgs; [
            openssl
          ];
        };
    };
  };
}
