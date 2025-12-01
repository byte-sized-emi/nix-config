{
  pkgs,
  version ? "v2.11.10",
}:
let
  versionNoPrefix = pkgs.lib.strings.removePrefix "v" version;
in
pkgs.appimageTools.wrapType2 {
  # or wrapType1
  inherit version;
  pname = "slippi-launcher";
  src = pkgs.fetchurl {
    url = "https://github.com/project-slippi/slippi-launcher/releases/download/${version}/Slippi-Launcher-${versionNoPrefix}-x86_64.AppImage";
    hash = "sha256-OrWd0jVqe6CzNbVRNlm2alt2NZ8uBYeHiASaB74ouW4=";
  };
  extraPkgs = pkgs: with pkgs; [ ];
}
