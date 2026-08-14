{
  den.aspects.ai.homeManager =
    { pkgs, lib, ... }:
    {
      home.packages = [ pkgs.mcp-nixos ];

      programs.mcp = {
        enable = true;
        servers = {
          context7 = {
            url = "https://mcp.context7.com/mcp";
          };
          nixos = {
            command = lib.getExe pkgs.mcp-nixos;
            args = [ ];
          };
        };
      };

      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;
        skills.blueprint-to-den-migration = ./ai/skills/blueprint-to-den-migration;
        settings =
          let
            bash = {
              "*" = "deny";
              "awk *" = "allow";
              "cat *" = "allow";
              "cargo check *" = "allow";
              "cargo clippy *" = "allow";
              "cargo test *" = "allow";
              "cargo build *" = "allow";
              "curl *" = "allow";
              "cut *" = "allow";
              "file *" = "allow";
              "find *" = "allow";
              "grep *" = "allow";
              "printf *" = "allow";
              "head *" = "allow";
              "jq *" = "allow";
              "ls *" = "allow";
              "rg *" = "allow";
              "sed *" = "allow";
              "sort *" = "allow";
              "stat *" = "allow";
              "tail *" = "allow";
              "tr *" = "allow";
              "uniq *" = "allow";
              "wc *" = "allow";
            };
          in
          {
            formatter = true;
            permission = {
              bash = bash // {
                "*" = "ask";
              };
              edit = "allow";
              webfetch = "allow";
              doom_loop = "ask";
              external_directory = "ask";
            };
            agent = {
              general = {
                mode = "subagent";
                model = "opencode/deepseek-v4-flash-free";
                permission = {
                  inherit bash;
                  edit = "allow";
                  webfetch = "allow";
                  websearch = "allow";
                  external_directory = "deny";
                  doom_loop = "deny";
                  task = "deny";
                };
              };
              explore = {
                mode = "subagent";
                model = "opencode/deepseek-v4-flash-free";
                permission = {
                  inherit bash;
                  edit = "deny";
                  webfetch = "allow";
                  external_directory = "deny";
                  doom_loop = "deny";
                  task = "deny";
                };
              };
            };
          };
      };
    };
}
