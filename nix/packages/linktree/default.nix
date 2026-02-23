{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "linktree";
  version = "0.1.3";

  src = ./.;

  installPhase = ''
    mkdir -p $out/
    cp *.html $out/
    cp *.css $out/
    cp *.webp $out/
    find "$out" -type f ! -name '*.etag' -print0 | while IFS= read -r -d "" file; do
      # compute md5 hash and write only the hash to a .etag file next to the original file
      md5sum "$file" | awk '{print $1}' > "$file.etag"
    done
  '';

  meta = with pkgs.lib; {
    homepage = "https://links.byte-sized.fyi";
    license = licenses.mit;
  };
}
