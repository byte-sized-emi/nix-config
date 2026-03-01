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
}
