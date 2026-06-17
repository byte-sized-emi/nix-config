{ flake, ... }:
{
  imports = with flake.homeModules; [
    default
  ];

  home.stateVersion = "26.11";
}
