{ config, pkgs, ... }:
{
  programs.firefox.enable = true;
  programs.firefox.configPath = "${config.xdg.configHome}/mozilla/firefox";
  home.packages = with pkgs; [
    ungoogled-chromium
  ];
}
