{
  apps.zed.homeManager =
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
          language_models = {
            opencode = {
              available_models = [
                {
                  name = "deepseek-v4-flash-free";
                  display_name = "DeepSeek V4 Flash Free";
                  max_tokens = 200000;
                  max_output_tokens = 128000;
                  protocol = "openai_chat";
                  reasoning_effort_levels = [
                    "low"
                    "high"
                    "max"
                  ];
                  interleaved_reasoning = true;
                  subscription = "free";
                }
                {
                  name = "hy3-free";
                  display_name = "Hy3 Free";
                  max_tokens = 190000;
                  max_output_tokens = 64000;
                  protocol = "openai_chat";
                  reasoning_effort_levels = [
                    "low"
                    "medium"
                    "high"
                  ];
                  interleaved_reasoning = true;
                  subscription = "free";
                }
              ];
              show_go_models = false;
              show_zen_models = false;
            };
          };
          agent = {
            subagent_model = {
              provider = "opencode";
              model = "deepseek-v4-flash-free";
            };
            default_profile = "write";
            dock = "right";
            default_model = {
              effort = "max";
              enable_thinking = true;
              provider = "opencode";
              model = "free/deepseek-v4-flash-free";
            };
            model_parameters = [ ];
          };
          code_lens = "on";
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
          languages.Nix.inlay_hints.enabled = true;
          lsp.nixd.settings.options = {
            nixos.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.nixlaptop.options";
            home-manager.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.nixlaptop.options";
            den.expr = "(builtins.getFlake (builtins.toString ./.)).den.options";
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
    };
}
