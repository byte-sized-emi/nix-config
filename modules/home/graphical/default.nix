{ pkgs, ... }:
{
  imports = [
    ./browser.nix
    ./zed.nix
    ./fonts.nix
    ./launcher.nix
    ./niri.nix
    ./noctalia.nix
    ./fachschaft.nix
  ];

  home.packages = with pkgs; [
    vlc
  ];
}
