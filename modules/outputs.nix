{
  inputs,
  den,
  stacks,
  ...
}:
{
  imports = [ inputs.den.flakeOutputs.packages ];
  den.schema.flake-system.includes = [
    den.aspects.auto-update
    stacks.linktree
  ];

  flake.formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
}
