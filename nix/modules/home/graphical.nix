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
    ./vicinae.nix
    ./niri.nix
    ./noctalia.nix
    ./swayidle.nix
    ./zed.nix
    ./steam.nix
    ./signal.nix
  ];

  xdg.desktopEntries.nix-config = {
    name = "Nix config (git.byte-sized.fyi)";
    comment = "My nix/NixOS config";
    exec = "xdg-open https://git.byte-sized.fyi/emilia/nix-config";
    terminal = false;
    type = "Application";
    categories = [ "Network" ];
    icon = "nix-snowflake";
  };

  # so stealing stuff from lucas gets even easier
  xdg.desktopEntries.keyruu-shinyflakes = {
    name = "Keyruu shinyflakes nix config";
    exec = "xdg-open https://github.com/keyruu/shinyflakes";
    comment = "Lucas / Keyruu shinyflakes repo";
    terminal = false;
    type = "Application";
    categories = [ "Network" ];
    icon = "nix-snowflake";
  };

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
