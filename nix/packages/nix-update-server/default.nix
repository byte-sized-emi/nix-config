{
  pkgs,
  inputs,
  pname,
  ...
}:
let
  naersk' = pkgs.callPackage inputs.naersk { };
in
naersk'.buildPackage {
  src = ./.;
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
}
