{ flake, ... }:
{
  imports = [
    flake.homeModules.default
    flake.homeModules.graphical
  ];

  home.stateVersion = "24.11";
}
