{
  config,
  pkgs,
  ...
}:
{
  sops.secrets =
    let
      owner = config.users.users.forgejo.name;
      group = config.users.groups.forgejo.name;
    in
    {
      "forgejo/actionsRunnerToken" = {
        inherit owner group;
      };
      "forgejo/instanceKey.pub" = {
        inherit owner group;
      };
      "forgejo/instanceKey" = {
        inherit owner group;
      };
    };

  systemd.tmpfiles.rules =
    let
      inherit (config.services.forgejo) customDir user group;
      header-template = ./forgejo/header.tmpl;
    in
    [
      "d '${customDir}/templates' 0750 ${user} ${group} - -"
      "d '${customDir}/templates/custom' 0750 ${user} ${group} - -"
      "L+ '${customDir}/templates/custom/header.tmpl' - - - - ${header-template}"
    ];

  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;
    settings = {
      APP_NAME = "byte-sized forgejo instance";
      server = {
        DOMAIN = config.settings.git.domain;
        ROOT_URL = "https://${config.settings.git.domain}";
        HTTP_PORT = 7001;
        SSH_PORT = 2222;
      };
      repository.ENABLE_PUSH_CREATE_USER = true;
      repository.signing = {
        FORMAT = "ssh";
        SIGNING_KEY = config.sops.secrets."forgejo/instanceKey.pub".path;
        SIGNING_NAME = "byte-sized.fyi Forgejo Instance";
        SIGNING_EMAIL = "forgejo@byte-sized.fyi";
      };
      session.COOKIE_SECURE = true;
      service = {
        ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
        SHOW_REGISTRATION_BUTTON = false;
      };
      openid.ENABLE_OPENID_SIGNUP = true;
      oauth2_client.ENABLE_AUTO_REGISTRATION = true;
      # TODO: configure SSO here
      cache = {
        ADAPTER = "twoqueue";
        HOST = "{\"size\":100, \"recent_ratio\":0.25, \"ghost_ratio\":0.5}";
      };
    };

    dump = {
      enable = true;
      interval = config.settings.backup.prepare.interval;
      type = "tar.gz";
      backupDir = "/var/backup/forgejo/";
    };
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.default = {
      enable = true;
      name = "monolith";
      url = "https://${config.settings.git.domain}";
      tokenFile = config.sops.secrets."forgejo/actionsRunnerToken".path;
      labels = [
        "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:rust-latest"
        "ubuntu-24.04:docker://ghcr.io/catthehacker/ubuntu:rust-24.04"
        "ubuntu-js-latest:docker://ghcr.io/catthehacker/ubuntu:js-latest"
      ];
      settings = {
        cache.enabled = true;
      };
    };
  };

  my.services.forgejo = {
    enable = true;
    port = config.services.forgejo.settings.server.HTTP_PORT;
    description = "Self-hosted Git service";
    external = {
      enable = true;
      domain = config.settings.git.domain;
    };
  };
}
