{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "linktree";
  version = "0.1.1";

  src = ./.;

  installPhase = ''
    mkdir -p $out/
    cp *.html $out/
    cp *.css $out/
    cp *.webp $out/
  '';

  meta = with pkgs.lib; {
    homepage = "https://links.byte-sized.fyi";
    license = licenses.mit;
  };
}
