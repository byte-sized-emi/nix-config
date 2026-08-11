{
  inputs,
  lib,
  den,
  ...
}:
{
  den.aspects.nixos-checks.checks =
    { pkgs, ... }:
    let
      nixosConfigurations = lib.mapAttrs (
        name: value: inputs.self.nixosConfigurations.${name}.config.system.build.toplevel
      ) den.hosts.${pkgs.stdenv.hostPlatform.system};
    in
    nixosConfigurations;
}
