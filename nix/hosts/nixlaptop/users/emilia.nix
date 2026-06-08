{ flake, ... }:
{
  imports = with flake.homeModules; [
    default
    graphical
    ai
    anki
    fachschaft
  ];

  programs.niri.settings.spawn-at-startup = [
    { command = [ "zeditor" ]; }
    { command = [ "todoist-electron" ]; }
    { command = [ "obsidian" ]; }
    { command = [ "thunderbird" ]; }
  ];

  home.stateVersion = "24.11";
}
