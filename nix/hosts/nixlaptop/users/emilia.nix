{ flake, ... }:
{
  imports = with flake.homeModules; [
    default
    graphical
    ai
  ];

  home.stateVersion = "24.11";
}
