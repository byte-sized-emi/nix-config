{ config, pkgs, settings, ... }:
{
  # TODO: SSH configuration
  services.forgejo = {
    enable = true;
    package = pkgs.forgejo-lts;
    settings = {
      server = {
        DOMAIN = settings.git.domain;
        ROOT_URL = "https://${settings.git.domain}";
        HTTP_PORT = 7001;
        SSH_PORT = 2222;
        SSH_DOMAIN = settings.git.ssh_domain;
      };
      repository.ENABLE_PUSH_CREATE_USER = true;
      session.COOKIE_SECURE = true;
      service.DISABLE_REGISTRATION = true;
      # TODO: configure SSO here
    };
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-actions-runner;
    instances.default = {
      enable = true;
      name = "monolith";
      url = "https://${settings.git.domain}";
      # Obtaining the path to the runner token file may differ
      # tokenFile should be in format TOKEN=<secret>, since it's EnvironmentFile for systemd
      tokenFile = "/var/forgejo/actions-runner-token";
      labels = [
        "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:rust-latest"
        "ubuntu-24.04:docker://ghcr.io/catthehacker/ubuntu:rust-24.04"
        "ubuntu-22.04:docker://ghcr.io/catthehacker/ubuntu:rust-22.04"
        "ubuntu-20.04:docker://ghcr.io/catthehacker/ubuntu:rust-20.04"
      ];
    };
  };

  services.cloudflared.tunnels.${settings.ingress_tunnel}.ingress = {
    ${settings.git.domain} = "http://localhost:${toString config.services.forgejo.settings.server.HTTP_PORT}";
    # ${settings.git.ssh_domain} = "ssh://localhost:${toString config.services.forgejo.settings.server.SSH_PORT}";
  };
}
