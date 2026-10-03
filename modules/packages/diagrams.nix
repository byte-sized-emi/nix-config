{
  den,
  lib,
  inputs,
  ...
}:
let
  # https://den.denful.dev/tutorials/case-study-diagrams/
  # nix eval .#diagrams --apply builtins.attrNames
  # nix eval .#diagrams.scope-topology

  diagram = inputs.den-diagram.lib;
  render = diagram.renderers { };

  # One pipeline run for the whole flake: every scope, host and user.
  fleetCapture = den.lib.capture.captureFleet { };

  hosts = lib.concatMap builtins.attrValues (builtins.attrValues den.hosts);

  hostViews =
    host:
    let
      # Cut one host's subtree out of the fleet capture.
      g = diagram.projectScope {
        inherit fleetCapture;
        kind = "host";
        inherit (host) name;
        direction = "TD";
      };
    in
    {
      "${host.name}-aspects" = render.toMermaid (diagram.graph.aspectsOnly g);
      "${host.name}-nixos" = render.toMermaid (diagram.graph.classSlice "nixos" g);
    };
in
{
  flake.diagrams = {
    scope-topology = render.toScopeTopologyMermaid fleetCapture;
    policy-resolution = render.toPolicyResolutionMapMermaid fleetCapture;
    pipe-flow = render.toPipeFlowMermaid fleetCapture;
    pipe-sequence = render.toPipeSequenceMermaid fleetCapture;
  }
  // lib.mergeAttrsList (map hostViews hosts);
}
