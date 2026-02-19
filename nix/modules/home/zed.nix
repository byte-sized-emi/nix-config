{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "git-firefly"
      "github-actions"
      "html"
      "material-icon-theme"
      "nix"
      "toml"
    ];

    userSettings = {
      autosave = "on_focus_change";
      features = {
        edit_prediction_provider = "copilot";
      };
      ui_font_size = 16;
      buffer_font_size = 15;
      theme = {
        mode = "dark";
        light = "One Light";
        dark = "One Dark";
      };
      buffer_font_family = "FiraCode Nerd Font";
      buffer_font_features = {
        calt = true;
      };
      load_direnv = "shell_hook";
      git_hosting_providers = [
        {
          provider = "forgejo";
          name = "git.byte-sized.fyi";
          base_url = "https://git.byte-sized.fyi";
        }
      ];
      calls.mute_on_join = true;
    };

    userKeymaps = [
      {
        context = "Pane";
        bindings = {
          ctrl-tab = "pane::ActivateNextItem";
          ctrl-shift-tab = "pane::ActivatePreviousItem";
        };
      }
      {
        context = "Editor";
        bindings = {
          "ctrl-t" = "workspace::NewCenterTerminal";
          "ctrl-k ctrl-c" = "editor::ToggleComments";
          "ctrl-k c" = "editor::ToggleComments";
        };
      }
    ];
  };
}
