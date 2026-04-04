{
  inputs,
  pkgs,
  ...
}:
{
  # usage:
  # imports = [
  #   flake.modules.nixos.nixpkgs-unstable
  # ];
  #
  # then add the `pkgs-unstable` argument at the top of the module

  _module.args.pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) config;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
}
