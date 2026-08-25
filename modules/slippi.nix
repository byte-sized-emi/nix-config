{ inputs, ... }:
{
  den.aspects.slippi.nixos = { perSystem, ... }: {
    imports = [ inputs.slippi.nixosModules.default ];
    environment.systemPackages = [
      perSystem.slippi.default
    ];
  };
}
