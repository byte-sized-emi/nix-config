{ inputs, ... }:
{
  den.aspects.ai.homeManager =
    {
      pkgs,
      lib,
      perSystem,
      config,
      ...
    }:
    {
      home.packages = [
        pkgs.mcp-nixos
        pkgs.ripgrep
        pkgs.socat
      ];

      imports = [ inputs.pi.homeModules.default ];

      sops.secrets."pi/neuralwatt" = { };

      # https://github.com/lukasl-dev/pi.nix
      programs.pi.coding-agent = {
        enable = true;
        package = perSystem.llm-agents.pi;

        extensions = [
          "npm:@dietrichgebert/ponytail"
          "npm:@aliou/pi-neuralwatt"
          "npm:pi-permission-modes" # see ./pi-permission-modes.nix
          "npm:pi-mcp-adapter"
          ./rtk.ts
        ];

        rules = ./BASE_AGENTS_PI.md;

        settings = {
          defaultProvider = "neuralwatt";
          defaultModel = "deepseek-v4-flash";
        };

        environment.NEURALWATT_API_KEY.file = config.sops.secrets."pi/neuralwatt".path;

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
              args = [ "serve" ];
            };
          };
        };
      };
    };
}
