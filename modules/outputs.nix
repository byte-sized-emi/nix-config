{ inputs, den, ... }:
{
  imports = [ inputs.den.flakeOutputs.packages ];
  den.schema.flake-system.includes = [
    den.aspects.auto-update
  ];
}
