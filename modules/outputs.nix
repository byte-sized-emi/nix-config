{
  inputs,
  den,
  __findFile,
  ...
}:
{
  imports = with inputs.den.flakeOutputs; [
    packages
    checks
  ];

  den.schema.flake.includes = [ den.policies.flake-to-systems ];

  den.schema.flake-system.includes = [
    <auto-update>
    <stacks/linktree>
    <nixos-checks>
    <build-paths>
    # <diagrams>
  ];

  flake.formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
}
