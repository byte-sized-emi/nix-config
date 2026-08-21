{ __findFile, ... }:
{
  stacks.control-server = {
    includes = [
      <control-server>
    ];

    nixos = { config, ... }: {
      my.control-server = {
        forgejo = {
          api = "https://${config.settings.git.domain}/api/v1";
          owner = "emilia";
          repo = "nix-config";
          tokenPath = config.sops.templates."control-server/forgejoTokenEnv".path;
        };
        webhook.secretPath = config.sops.templates."control-server/webhookSecretEnv".path;
        publicUrl = "https://control-server.service.byte-sized.fyi";
      };

      sops.secrets."control-server/forgejoToken" = {
        owner = "control-server";
        group = "control-server";
      };
      sops.secrets."control-server/webhookSecret" = {
        owner = "control-server";
        group = "control-server";
      };

      # Render the raw secrets into the KEY=value env files the service reads
      # via systemd EnvironmentFile.
      sops.templates."control-server/forgejoTokenEnv" = {
        owner = "control-server";
        group = "control-server";
        content = ''
          FORGEJO_TOKEN=${config.sops.placeholder."control-server/forgejoToken"}
        '';
      };
      sops.templates."control-server/webhookSecretEnv" = {
        owner = "control-server";
        group = "control-server";
        content = ''
          WEBHOOK_SECRET=${config.sops.placeholder."control-server/webhookSecret"}
        '';
      };

      my.services.control-server = {
        enable = true;
        port = config.my.control-server.port;
        description = "NixOS deployment control plane";
        internal.enable = true;
      };
    };
  };
}
