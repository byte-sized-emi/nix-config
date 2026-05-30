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
    settings = {
      permission = {
        edit = "allow";
        bash = "ask";
        webfetch = "allow";
        doom_loop = "ask";
        external_directory = "ask";
      };
    };
  };

}
