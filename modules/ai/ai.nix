{ inputs, lib, ... }:
{
  den.aspects.ai.homeManager =
    {
      pkgs,
      perSystem,
      config,
      ...
    }:
    {
      home.packages = with pkgs; [
        mcp-nixos
        ripgrep
        socat
        python3
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
          "npm:pi-mcp-adapter"
          # "npm:pi-sandbox"
          "npm:pi-web-access"
          "npm:@juicesharp/rpiv-todo"
          # "git:github.com/byte-sized-emi/pi-permission-modes"
          ./rtk.ts
          ./sounds.ts
          perSystem.pi-bwrap-sandbox.default
        ];

        rules = ./BASE_AGENTS_PI.md;

        settings = {
          defaultProvider = "neuralwatt";
          defaultModel = "deepseek-v4-flash";
        };

        environment.NEURALWATT_API_KEY.file = config.sops.secrets."pi/neuralwatt".path;
      };

      home.file.".pi/agent/extensions/bwrap-sandbox.json".text = builtins.toJSON {
        writePaths = [
          "."
          "~/.cache/nix"
        ];
        readPaths = [ "~/.config/nix" ];
        denyReadPaths = [
          "~/.ssh"
          "~/.aws"
          "~/.gnupg"
          "~/.config/sops"
        ];
      };

      home.file.".pi/agent/sandbox.json".text = builtins.toJSON {
        enabled = true;
        sandboxUserShell = true; # Sandbox commands entered with `!`. Defaults to true
        permissionPromptTimeoutSeconds = 600; # Defaults to 10 minutes; 0 waits indefinitely
        allowBrowserProcess = true; # If you want to use agent-browser or similar Chrome setup
        network = {
          disabled = true; # Set true for direct network access (no proxy/--unshare-net) while keeping filesystem sandboxing
          allowLocalBinding = true; # ditto
          allowAllUnixSockets = true; # ditto
          allowUnauthenticatedSocksProxy = true; # Enables Git-over-SSH on macOS
          allowSSHAgentSocket = true; # Allow the current SSH agent socket (macOS SSH commit signing)
          allowedDomains = [
            "github.com"
            "*.github.com"
          ];
          deniedDomains = [ ];
        };
        filesystem = {
          # For READS:
          # - ANY read is prompted unless the path is in allowRead or allowWrite
          # - Granting a prompt adds to allowRead, which overrides denyRead
          # - denyRead is not a hard-block; it just marks regions as denied by default
          denyRead = [
            "/Users"
            "/home"
          ];
          allowRead = [
            "."
            "~/.config"
            "~/.local"
            "Library"
          ];

          # For WRITES:
          # - allowWrite also grants read access to the same paths
          # - empty ALLOW means no write access at all
          # - DENY takes precedence and is never prompted
          allowWrite = [
            "."
            "/tmp"
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
