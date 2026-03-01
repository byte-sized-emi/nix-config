{
  pkgs,
  perSystem,
  ...
}:
pkgs.stdenvNoCC.mkDerivation {
  pname = "blog";
  version = "0.1.0";

  src = ./.;

  buildPhase = ''
    mkdir -p $out/
    ${pkgs.lib.getExe perSystem.self.blog-builder} build --input "$src" --output "$out"
  '';

  installPhase = ''
    mkdir -p $out/
    find "$out" -type f ! -name '*.etag' -print0 | while IFS= read -r -d "" file; do
      # compute md5 hash and write only the hash to a .etag file next to the original file
      md5sum "$file" | awk '{print $1}' > "$file.etag"
    done
  '';

  meta = with pkgs.lib; {
    homepage = "https://blog.byte-sized.fyi";
    license = licenses.mit;
  };
}
