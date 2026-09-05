{
  apps.zed = {
    nixos = {
      programs.nix-ld.enable = true;
    };
    homeManager = { perSystem, pkgs, ... }: {
      home.packages = with perSystem.llm-agents; [
        agent-browser
        rtk
        pkgs.rust-analyzer
      ];

      # TODO: fix agent sandbox
      programs.zed-editor = {
        enable = true;
        package = pkgs.zed-editor;
        enableMcpIntegration = true;
        # extraPackages = with pkgs; [ bubblewrap ];
        # name needs to be one of these (warning, very long): https://github.com/zed-industries/extensions/tree/main/extensions
        extensions = [
          "git-firefly"
          "github-actions"
          "html"
          "material-icon-theme"
          "nix"
          "toml"
          "path-server-lsp"
        ];

        userSettings = {
          language_models = {
            openai_compatible.NeuralWatt = {
              api_url = "https://api.neuralwatt.com/v1";
              available_models = [
                {
                  name = "deepseek-v4-flash";
                  max_tokens = 1000000;
                  max_output_tokens = 262000;
                  max_completion_tokens = 100000;
                  reasoning_effort = "medium";
                  capabilities = {
                    tools = true;
                    images = false;
                    parallel_tool_calls = true;
                    prompt_cache_key = false;
                    chat_completions = true;
                    interleaved_reasoning = true;
                    max_tokens_parameter = true;
                  };
                }
                {
                  name = "glm-5.2";
                  max_tokens = 1000000;
                  max_output_tokens = 128000;
                  max_completion_tokens = 100000;
                  reasoning_effort = "medium";
                  capabilities = {
                    tools = true;
                    images = false;
                    parallel_tool_calls = true;
                    prompt_cache_key = false;
                    chat_completions = true;
                    interleaved_reasoning = true;
                    max_tokens_parameter = false;
                  };
                }
              ];
            };
          };
          agent = {
            sandbox_permissions = {
              allow_unsandboxed = true;
              # network_hosts = [
              #   "raw.githubusercontent.com"
              # ];
            };
            play_sound_when_agent_done = "when_hidden";
            tool_permissions = {
              default = "confirm";
              tools = {
                terminal = {
                  default = "confirm";
                  always_allow =
                    let
                      basic_commands = [
                        "awk"
                        "cat"
                        "curl"
                        "cut"
                        "file"
                        "find"
                        "grep"
                        "printf"
                        "head"
                        "jq"
                        "ls"
                        "rg"
                        "sed"
                        "sort"
                        "stat"
                        "tail"
                        "tr"
                        "uniq"
                        "wc"
                      ];
                    in
                    [
                      { pattern = "^nix\\s+(build|eval)\\b"; }
                      { pattern = "^nixos-rebuild build\\b"; }
                      { pattern = "^cargo\\s+(check|clippy|test|build)\\b"; }
                    ]
                    ++ map (cmd: { pattern = "^${cmd}\\b"; }) basic_commands
                    ++ map (cmd: { pattern = "^rtk\\s+${cmd}\\b"; }) basic_commands;
                };
                edit_file = {
                  default = "allow";
                };
                write_file = {
                  default = "allow";
                };
                fetch = {
                  default = "allow";
                };
              };
            };
            subagent_model = {
              provider = "neuralwatt";
              model = "deepseek-v4-flash";
            };
            compaction_model = {
              provider = "neuralwatt";
              model = "deepseek-v4-flash";
            };
            default_profile = "write";
            dock = "right";
            default_model = {
              effort = "medium";
              enable_thinking = true;
              provider = "NeuralWatt";
              model = "deepseek-v4-flash";
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
          cli_default_open_behavior = "existing_window";
          edit_predictions.provider = "zed";
          project_panel.dock = "left";
          outline_panel.dock = "left";
          collaboration_panel.dock = "left";
          git_panel.dock = "left";
          agent_servers = {
            opencode = {
              default_config_options = {
                effort = "high";
                model = "opencode/big-pickle";
                mode = "build";
              };
              type = "custom";
              command = "opencode";
              args = [ "acp" ];
              env = { };
            };
          };
          languages.Nix.inlay_hints.enabled = true;
          lsp.path-server-lsp.settings = {
            basePath = [
              "\${workspaceFolder}"
              "\${document}"
            ];
            completion = {
              triggerNextCompletion = true;
            };
            highlight = {
              enable = true;
              highlightDirectory = true;
            };
          };
          lsp.nixd.initialization_options.options = {
            nixos.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.nixnest.options";
            home-manager.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.nixlaptop.options.home-manager.users.type.getSubOptions []";
            den.expr = "(builtins.getFlake (builtins.toString ./.)).den.options";
          };
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
              alt-left = "pane::GoBack";
              alt-right = "pane::GoForward";
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
          {
            bindings = {
              ctrl-alt-tab = "workspace::ActivateNextPane";
              ctrl-alt-shift-tab = "workspace::ActivatePreviousPane";
            };
          }
        ];
      };
    };
  };
}
