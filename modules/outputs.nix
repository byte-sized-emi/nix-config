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
    devShells
  ];

  den.schema.flake.includes = [ den.policies.flake-to-systems ];

  den.schema.flake-system.includes = [
    <auto-update>
    <stacks/linktree>
    <nixos-checks>
    <build-paths>
    <control-server>
    <dev-shell>
    # <diagrams>
  ];

  flake.formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
}
