{ pkgs, inputs, ... }:
let
  naersk' = pkgs.callPackage inputs.naersk { };
in
naersk'.buildPackage {
  src = ./.;
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
    nixos-rebuild
  ];
  postInstall = ''
    wrapProgram $out/bin/nix-update-server --prefix PATH : ${
      pkgs.lib.makeBinPath [
        pkgs.git
        pkgs.nixos-rebuild
      ]
    }
  '';
}
