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
      providers."@marcjulian/obsidian" = {
        preferences.vaultPath = "/home/emilia/Documents/everything";
      };
      rootSearch.searchFiles = false;
      closeOnFocusLoss = true;
      launcher_window.opacity = 0.9;
      # fallbacks = [
      #   "files:search"
      # ];
    };

    # extension names: https://github.com/vicinaehq/extensions/tree/main/extensions
    # raycast extensions come from https://github.com/raycast/extensions.git
    extensions = with perSystem.vicinae-extensions; [
      bluetooth
      nix
      wifi-commander
      (perSystem.vicinae.mkRayCastExtension {
        name = "obsidian";
        sha256 = "sha256-ryK/5sTBIJk9mIAYuAqdkGJhs7h3D4+bAj8+zKjLLMg=";
        rev = "2735ebd704f2bcd6fa043811c95009fc812f40f2";
      })
    ];
  };
}
