{ inputs, den, ... }:
{
  den.aspects.diagrams.packages =
    let
      diagram = inputs.den-diagram.lib;
      aspectData = diagram.graph.ofNamespace { aspects = den.aspects; };
      fleetCapture = den.lib.capture.captureFleet { };
      fleetData = diagram.fleet.of {
        hosts = den.hosts;
        flakeName = "nix-config";
      };
    in
    {
      scope-topology-diagram = diagram.toScopeTopologyMermaid fleetCapture;
      policy-resolution-diagram = diagram.toPolicyResolutionMapMermaid fleetCapture;
      fleet-dag-diagram = diagram.toFleetDagMermaid fleetCapture;
      fleet-diagram = diagram.toFleetTreemapMermaid fleetData;
      aspect-diagram = diagram.toC4Context aspectData;
    };
}
