{
  config,
  pkgs,
  ...
}:
{
  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
    };
    settings = {
      providers."@ricoberger/gitmoji" = {
        preferences = {
          copy = "code";
          action = "paste";
        };
      };
      rootSearch.searchFiles = false;
      close_on_focus_loss = true;
      launcher_window.opacity = 0.9;
      theme = {
        light = {
          name = "vicinae-light";
          icon_theme = "Papirus-Light";
        };
        dark = {
          name = "vicinae-dark";
          icon_theme = "Papirus-Dark";
        };
      };
    };

    # extension names: https://github.com/vicinaehq/extensions/tree/main/extensions
    # raycast extensions come from https://github.com/raycast/extensions
    extensions =
      let
        extensionsRepo = pkgs.fetchFromGitHub {
          owner = "vicinaehq";
          repo = "extensions";
          rev = "48123bc3361f5ed462cc931203dfb7434c3adaf6";
          sha256 = "sha256-p/zdh8pyPbwNQ0G4Swc+mFB8nvjQMwQ0NlLYaugI1pU=";
        };
        mkVicinaeExtension =
          name:
          config.lib.vicinae.mkExtension {
            name = name;
            src = extensionsRepo + "/extensions/${name}";
          };
      in
      [
        # (mkVicinaeExtension "systemd") # currently non-functional
        (mkVicinaeExtension "bluetooth")
        (mkVicinaeExtension "nix")
        (mkVicinaeExtension "wifi-commander")
        (mkVicinaeExtension "niri")
        (mkVicinaeExtension "power-profile")
        (mkVicinaeExtension "zed-recents")
        (config.lib.vicinae.mkRayCastExtension {
          name = "gitmoji";
          sha256 = "sha256-xYrn+dnKaA0ghCR32zTSpj0aPWH2Xp8yc4NZMLqukUA=";
          rev = "265957a2237e8b424e9a8f2f4ed6e8efbce56f8e";
        })
      ];
  };
}
