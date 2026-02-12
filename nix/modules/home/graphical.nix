{ pkgs, inputs, ... }:
let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    ./browser.nix
    ./fachschaft.nix
    ./fonts.nix
    ./launcher.nix
    ./niri.nix
    ./noctalia.nix
    ./swayidle.nix
    ./zed.nix
  ];

  home.packages =
    let
      normal-packages = with pkgs; [
        kdePackages.kate
        discord
        obsidian
        # spotify
        signal-desktop
        slack
        todoist-electron
        jetbrains.idea
        xournalpp
        wev
        element-desktop
        keepassxc
        vlc
        libreoffice
      ];
      unstable-packages = with pkgs-unstable; [
        deezer-enhanced
        mission-center
        beeper
      ];
    in
    normal-packages ++ unstable-packages;
}
