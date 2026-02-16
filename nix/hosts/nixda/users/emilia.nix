{ flake, ... }:
{
  imports = with flake.homeModules; [
    default
    graphical
  ];

  home.stateVersion = "24.11";
}
