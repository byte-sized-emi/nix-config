{ config, pkgs, ... }:
{
  users = {
    groups.renovate.gid = 1005;
    users = {
      renovate = {
        isSystemUser = true;
        uid = 1005;
        group = "renovate";
      };
    };
  };

  sops.secrets = {
    "renovate/token".owner = "renovate";
    "renovate/private_key".owner = "renovate";
    "renovate/github_pat".owner = "renovate";
  };

  services.renovate = {
    enable = true;
    environment = {
      LOG_LEVEL = "debug";
    };
    credentials = {
      RENOVATE_TOKEN = config.sops.secrets."renovate/token".path;
      RENOVATE_GIT_PRIVATE_KEY = config.sops.secrets."renovate/private_key".path;
      RENOVATE_GITHUB_COM_TOKEN = config.sops.secrets."renovate/github_pat".path;
    };
    schedule = "hourly";

    runtimePackages = with pkgs; [
      bash
      gnupg
      openssh
      nodejs
      yarn
      cargo
      config.nix.package
    ];

    settings = {
      endpoint = "https://git.byte-sized.fyi";
      gitAuthor = "Renovate bot <renovate@byte-sized.fyi>";
      platform = "forgejo";
      platformAutomerge = false;
      automergeStrategy = "rebase";
      autodiscover = true;
      nix.enabled = true;
      lockFileMaintenance = {
        enabled = true;
        schedule = [ "after 4am and before 5am" ];
      };

      # Recommended defaults from https://github.com/NuschtOS/nixos-modules/blob/db6f2a33500dadb81020b6e5d4281b4820d1b862/modules/renovate.nix
      cachePrivatePackages = true;
      configMigration = true;
      optimizeForDisabled = true;
      persistRepoData = true;
      repositoryCache = "enabled";
    };
  };
}
