{
  programs.zed-editor = {
    enable = true;

    userSettings = {
      features = {
        edit_prediction_provider = "copilot";
      };
      ui_font_size = 16;
      buffer_font_size = 15;
      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };
      buffer_font_family = "Fira Code";
      buffer_font_features = {
        calt = true;
      };
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
          "ctrl-k ctrl-c" = "editor::ToggleComments";
          "ctrl-k c" = "editor::ToggleComments";
        };
      }
    ];
  };
}
