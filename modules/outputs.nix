{
  inputs,
  den,
  stacks,
  ...
}:
{
  imports = with inputs.den.flakeOutputs; [
    packages
    checks
    devShells
  ];

  den.schema.flake.includes = [ den.policies.flake-to-systems ];

  den.schema.flake-system.includes = [
    den.aspects.auto-update
    stacks.linktree
    stacks.nw-usage
    # den.aspects.nixos-checks
    den.aspects.dev-shell
    # den.aspects.diagrams
  ];

  flake.formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
}
