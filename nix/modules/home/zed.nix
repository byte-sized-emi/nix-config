{ pkgs, ... }:
{
  programs.zed-editor = {
    package = pkgs.zed-editor;
    enable = true;
    enableMcpIntegration = true;
    extensions = [
      "git-firefly"
      "github-actions"
      "html"
      "material-icon-theme"
      "nix"
      "toml"
    ];

    userSettings = {
      format_on_save = "on";
      indent_guides = {
        enabled = true;
        coloring = "indent_aware";
      };
      colorize_brackets = true;
      autosave = "on_focus_change";
      icon_theme = "Material Icon Theme";
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
      agent_servers = {
        opencode = {
          type = "custom";
          command = "opencode";
          args = [ "acp" ];
          env = { };
        };
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
          "ctrl-t" = "workspace::NewCenterTerminal";
          "ctrl-k ctrl-c" = "editor::ToggleComments";
          "ctrl-k c" = "editor::ToggleComments";
        };
      }
    ];
  };
}
