{ inputs, perSystem, ... }:
{
  imports = [
    inputs.vicinae.homeManagerModules.default
  ];

  services.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = 1;
      };
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
    extensions = with perSystem.vicinae-extensions; [
      # bluetooth
      nix
      wifi-commander
      niri
      power-profile
      (perSystem.vicinae.mkRayCastExtension {
        name = "gitmoji";
        sha256 = "sha256-xYrn+dnKaA0ghCR32zTSpj0aPWH2Xp8yc4NZMLqukUA=";
        rev = "265957a2237e8b424e9a8f2f4ed6e8efbce56f8e";
        # rev = "2735ebd704f2bcd6fa043811c95009fc812f40f2";
      })
    ];
  };
}
