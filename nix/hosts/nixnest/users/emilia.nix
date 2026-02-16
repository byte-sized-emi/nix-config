{ flake, ... }:
{
  imports = with flake.homeModules; [
    default
  ];

  home.stateVersion = "24.11";
}
