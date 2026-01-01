{ pkgs, ... }:
{
  imports = [
    ./browser.nix
    ./zed.nix
    ./fonts.nix
    ./launcher.nix
    ./desktop.nix
    ./fachschaft.nix
  ];

  home.packages = with pkgs; [
    vlc
  ];
}
