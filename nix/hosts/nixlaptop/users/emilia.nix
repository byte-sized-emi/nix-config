{ flake, ... }:
{
  imports = with flake.homeModules; [
    default
    graphical
    ai
    anki
  ];

  home.stateVersion = "24.11";
}
