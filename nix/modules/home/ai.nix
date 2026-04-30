{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.mcp-nixos ];

  programs.opencode = {
    enable = true;
    settings = {
      permission = {
        edit = "allow";
        bash = "ask";
        webfetch = "allow";
        doom_loop = "ask";
        external_directory = "ask";
      };
      mcp = {
        context7 = {
          enabled = true;
          type = "remote";
          url = "https://mcp.context7.com/mcp";
        };
        nixos = {
          enabled = true;
          type = "local";
          command = [
            (lib.getExe pkgs.mcp-nixos)
          ];
        };
      };
    };
  };
}
