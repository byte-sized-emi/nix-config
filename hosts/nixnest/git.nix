{
  config,
  pkgs,
  settings,
  ...
}:
{
  services.forgejo = {
    enable = true;
    package = pkgs.forgejo-lts;
    settings = {
      server = {
        DOMAIN = settings.git.domain;
        ROOT_URL = "https://${settings.git.domain}";
        HTTP_PORT = 7001;
        SSH_PORT = 2222;
      };
      repository.ENABLE_PUSH_CREATE_USER = true;
      session.COOKIE_SECURE = true;
      service.DISABLE_REGISTRATION = true;
      # TODO: configure SSO here
    };

    dump = {
      enable = true;
      interval = settings.backup.prepare.interval;
      type = "tar.gz";
      backupDir = "/var/backup/forgejo/";
    };
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.default = {
      enable = true;
      name = "monolith";
      url = "https://${settings.git.domain}";
      tokenFile = config.sops.secrets."forgejo/actionsRunnerToken".path;
      labels = [
        "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:rust-latest"
        "ubuntu-24.04:docker://ghcr.io/catthehacker/ubuntu:rust-24.04"
        "ubuntu-22.04:docker://ghcr.io/catthehacker/ubuntu:rust-22.04"
        "ubuntu-20.04:docker://ghcr.io/catthehacker/ubuntu:rust-20.04"
      ];
    };
  };

  services.cloudflared.tunnels.${settings.ingress_tunnel}.ingress = {
    ${settings.git.domain} =
      "http://localhost:${toString config.services.forgejo.settings.server.HTTP_PORT}";
  };
}
