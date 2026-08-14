{
  den.aspects.dev-shell.devShells = { pkgs, ... }: {
    default = pkgs.mkShell {
      inputs = with pkgs; [
        rust-analyzer
        rustfmt
        rustc
        clippy
        cargo
      ];
    };
  };
}
