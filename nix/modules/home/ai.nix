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
    settings =
      let
        bash = {
          "*" = "deny";
          "head *" = "allow";
          "ls *" = "allow";
          "cat *" = "allow";
          "grep *" = "allow";
          "rg *" = "allow";
          "find *" = "allow";
          "stat *" = "allow";
          "file *" = "allow";
          "tail *" = "allow";
          "wc *" = "allow";
          "sort *" = "allow";
          "uniq *" = "allow";
          "cut *" = "allow";
          "awk *" = "allow";
          "sed *" = "allow";
          "jq *" = "allow";
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
            permission = {
              inherit bash;
              edit = "deny";
              webfetch = "allow";
              external_directory = "deny";
              doom_loop = "deny";
              task = "deny";
            };
          };
          explore = {
            mode = "subagent";
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

}
