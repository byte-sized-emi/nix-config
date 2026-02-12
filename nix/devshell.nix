{ pkgs, perSystem, ... }:
pkgs.mkShell {
  inputsFrom = [ perSystem.self.nix-update-server ];
  buildInputs = with pkgs; [
    bacon
    rust-analyzer
    rustfmt
    rustc
    clippy
  ];
}
