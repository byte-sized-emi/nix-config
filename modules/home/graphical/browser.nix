{ pkgs, ... }:
{
  programs.firefox.enable = true;
  home.packages = with pkgs; [
    ungoogled-chromium
  ];
}
