{
  inputs,
  pkgs,
  ...
}:
{
  _module.args.pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) config;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
}
