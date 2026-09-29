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

        extensions = [
          "npm:@dietrichgebert/ponytail"
          "npm:@aliou/pi-neuralwatt"
          "npm:pi-sandbox"
          "npm:pi-mcp-adapter"
          ./rtk.ts
        ];

        rules = ./BASE_AGENTS_PI.md;

        settings = {
          defaultProvider = "neuralwatt";
          defaultModel = "deepseek-v4-flash";
        };

        environment.NEURALWATT_API_KEY.file = config.sops.secrets."pi/neuralwatt".path;

        # https://github.com/lukasl-dev/pi.nix#jail
        jail = {
          enable = false;
          permissions =
            combinators: with combinators; [
              network
              mount-cwd

              (readwrite "/nix")
              (set-env "NIX_REMOTE" "daemon")

              # TODO: change to a rw-bind to a seperate folder, to keep /tmp even more seperate?
              (readwrite "/tmp")

              (add-pkg-deps [
                pkgs.git
                pkgs.nix
                pkgs.jq
                pkgs.curl
                pkgs.ripgrep
                perSystem.llm-agents.rtk
                # pkgs.cargo
                # pkgs.rustc
                # perSystem.llm-agents.agent-browser
              ])
            ];
        };
      };

      home.file.".pi/agent/sandbox.json".text = builtins.toJSON {
        enabled = true;
        permissionPromptTimeoutSeconds = 600;
        network = {
          allowLocalBinding = true;
          allowUnauthenticatedSocksProxy = true;
          allowAllUnixSockets = true;
          allowedDomains = [
            "localhost"
            "127.0.0.1"
            "html.duckduckgo.com"
            "*.npmjs.org"
            "*.pypi.org"
            "*.github.com"
            "github.com"
            "raw.githubusercontent.com"
            "*.byte-sized.fyi"
            "mcp.context7.com"
            "*"
          ];
          deniedDomains = [ ];
        };
        filesystem = {
          allowRead = [
            "/nix"
            "."
            "~/.cargo"
            "~/.cache"
          ];
          denyRead = [
            "/Users"
            ".env"
            ".env.*"
          ];
          allowWrite = [
            "."
            "/tmp"
            "~/.pi/"
            "~/.cache/uv"
            "~/.cache/nix"
            "~/.rustup"
          ];
          denyWrite = [
            ".env"
            ".env.*"
            "*.pem"
            "*.key"
          ];
        };
      };

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
}
