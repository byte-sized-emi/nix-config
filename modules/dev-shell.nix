{
  den.aspects.dev-shell.devShells = { pkgs, ... }: {
    default = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
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
}
