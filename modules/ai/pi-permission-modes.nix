{
  den.aspects.ai.homeManager = {
    home.file.".pi/agent/permission-mode/permission-mode.json".text =
      let
        # Shared OS-sandbox profile for pi-permission-modes (writable varies per mode).
        sandboxWithWritable = writable: {
          enabled = true;
          inherit writable;
          allowRead = [
            "/nix"
          ];
          allowWrite = [
            "/tmp"
            "."
            "~"
          ];
          denyWrite = [ ];
          denyRead = [
            "~/.ssh"
            "~/.aws"
            "~/.gnupg"
            "~/.netrc"
            "~/.git-credentials"
            "~/.pypirc"
            "~/.gem/credentials"
            "~/.vault-token"
            "~/.password-store"
            "~/.pi/agent/auth.json"
            "~/.pi/agent/oauth.json"
          ];
          network = {
            allowAllUnixSockets = true;
            allowedDomains = [
              # package registries + git hosts
              "npmjs.org"
              "*.npmjs.org"
              "registry.npmjs.org"
              "registry.yarnpkg.com"
              "pypi.org"
              "*.pypi.org"
              "github.com"
              "*.github.com"
              "api.github.com"
              "raw.githubusercontent.com"
              # local MCP / tools
              "localhost"
              "127.0.0.1"
              # web search, self, MCP servers
              "html.duckduckgo.com"
              "*.byte-sized.fyi"
              "mcp.context7.com"
              # WARN: open network
              "*"
            ];
            deniedDomains = [ ];
          };
        };

        # Secret-file gate at the tool layer. Sandbox lists drop globs on Linux, so
        # these live in the permission policy, which the extension matches itself.
        allowedPaths = {
          "*" = "allow";
          "*.env" = "deny";
          "*.env.*" = "deny";
          "*.pem" = "deny";
          "*.key" = "deny";
        };

        # Common policy for the three sandboxed modes: secret-file gate, reads free,
        # out-of-project access asks. A mode's surface below is merged in.
        basePermission = {
          path = allowedPaths;
          external_directory = "ask";
          read = "allow";
          grep = "allow";
          find = "allow";
          ls = "allow";
        };

        allAsk = {
          write = "ask";
          edit = "ask";
          bash = {
            "*" = "ask";
          };
          web_search = "ask";
          tool = "ask";
          skill = "ask";
        };

        allAllow = {
          read = "allow";
          write = "allow";
          edit = "allow";
          grep = "allow";
          find = "allow";
          ls = "allow";
          bash = {
            "*" = "allow";
          };
          web_search = "allow";
          tool = "allow";
          skill = "allow";
        };

        mdOnly = {
          "*" = "deny";
          "*.md" = "allow";
          "*.markdown" = "allow";
        };

        permissionModes = {
          "$schema" =
            "https://raw.githubusercontent.com/wynainfo/pi-permission-modes/main/schemas/permission-mode.schema.json";
          defaultMode = "default";
          cycleOrder = [
            "default"
            "plan"
            "build"
            "yolo"
          ];
          modes = {
            default = {
              label = "Default";
              color = "muted";
              sandbox = sandboxWithWritable true;
              permission = basePermission // allAllow;
            };
            plan = {
              label = "Plan Mode";
              color = "mdLink";
              systemPrompt = "@plan";
              sandbox = sandboxWithWritable false;
              permission =
                basePermission
                // allAsk
                // {
                  write = mdOnly;
                  edit = mdOnly;
                  bash = {
                    "*" = "allow";
                  };
                  web_search = "allow";
                };
            };
            build = {
              label = "Build";
              color = "accent";
              sandbox = sandboxWithWritable true;
              permission = basePermission // allAllow;
            };
            yolo = {
              label = "YOLO";
              color = "error";
              sandbox = {
                enabled = false;
                writable = true;
              };
              bypassProtectedPaths = true;
              permission = {
                path = {
                  "*" = "allow";
                };
                external_directory = "allow";
              }
              // allAllow;
            };
          };
        };
      in
      builtins.toJSON permissionModes;
  };
}
