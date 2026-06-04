{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./browser.nix
    ./email.nix
    ./fonts.nix
    ./niri.nix
    ./noctalia.nix
    ./signal.nix
    ./steam.nix
    ./swayidle.nix
    ./vicinae.nix
    ./zed.nix
  ];

  programs.zsh.shellAliases.sudo = lib.mkForce "pkexec --keep-cwd";

  # ls /run/current-system/sw/share/applications # for global packages
  # ls /etc/profiles/per-user/$(id -n -u)/share/applications # for user packages
  # ls ~/.nix-profile/share/applications # for home-manager packages

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

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "application/pdf" = "com.github.xournalpp.xournalpp.desktop";
      "application/x-xoj" = "com.github.xournalpp.xournalpp.desktop";
      "application/x-xojpp" = "com.github.xournalpp.xournalpp.desktop";
      "application/x-xopp" = "com.github.xournalpp.xournalpp.desktop";
      "application/x-xopt" = "com.github.xournalpp.xournalpp.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };

  home.packages = with pkgs; [
    kdePackages.kate
    kdePackages.filelight
    discord
    obsidian
    # spotify
    signal-desktop
    todoist-electron
    xournalpp
    wev
    element-desktop
    vlc
    libreoffice
    file
    jellyfin-desktop
    deezer-enhanced
    mission-center
    beeper
  ];
}
