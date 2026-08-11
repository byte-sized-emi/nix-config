{
  inputs,
  lib,
  den,
  ...
}:
{
  den.aspects.build-paths.packages =
    { pkgs, ... }:
    let
      nixosConfigurations = lib.mapAttrs (
        name: value: toString inputs.self.nixosConfigurations.${name}.config.system.build.toplevel
      ) den.hosts.${pkgs.stdenv.hostPlatform.system};
      text = builtins.toJSON {
        inherit nixosConfigurations;
      };
    in
    {
      build-paths = pkgs.writeTextFile {
        name = ".build-paths.json";
        inherit text;
      };
    };
}
