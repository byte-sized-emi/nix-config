{
  den.aspects.ai.homeManager =
    {
      pkgs,
      lib,
      perSystem,
      ...
    }:
    {
      home.packages = [ pkgs.mcp-nixos ];

      xdg.configFile."zed/AGENTS.md".source = ./BASE_AGENTS.md;

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
          icm = {
            command = lib.getExe perSystem.llm-agents.icm;
            args = [ ];
          };
        };
      };
    };
}
