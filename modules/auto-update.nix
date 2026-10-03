{ inputs, lib, ... }:
{
  den.aspects.auto-update = {
    desktop.nixos = {
      services.comin = {
        desktop.enable = true;
        buildConfirmer.mode = "manual";
        deployConfirmer.mode = "manual";
      };
    };
    nixos = { pkgs, config, ... }: {
      imports = [ inputs.comin.nixosModules.comin ];

      environment.systemPackages = [ pkgs.libnotify ];

      sops.secrets."comin-access-token" = { };

      services.comin = {
        enable = true;
        submodules = true;
        postDeploymentCommand = lib.getExe (
          pkgs.writeShellApplication {
            name = "comin-post-deployment";
            runtimeInputs = [ pkgs.curl ];
            text = ''
              curl -Ls \
                -H "Title: Deploy $COMIN_HOSTNAME" \
                -d "Status: $COMIN_STATUS
                Commit: $COMIN_GIT_MSG ($COMIN_GIT_SHA)
                $COMIN_ERROR_MSG" \
                https://ntfy.service.byte-sized.fyi/deploys
            '';
          }
        );
        remotes = [
          {
            name = "origin";
            url = "https://git.byte-sized.fyi/emilia/nix-config.git";
            branches.main.name = "main";
            poller.period = 180;
            auth = {
              username = "x-access-token";
              access_token_path = config.sops.secrets."comin-access-token".path;
            };
          }
        ];
      };

      services.fluent-bit = {
        enable = true;
        settings = {
          pipeline = {
            inputs = [
              {
                name = "systemd";
                tag = "comin";
                strip_underscores = true;
                lowercase = true;
                systemd_filter = "_SYSTEMD_UNIT=comin.service";
              }
            ];
            filters = [
              {
                name = "record_modifier";
                match = "comin";
                allowlist_key = [
                  "systemd_unit"
                  "message"
                  "hostname"
                  "machine_id"
                  "gid"
                  "pid"
                  "exe"
                  "service_name"
                  "boot_id"
                  "detected_level"
                  "priority"
                  "cmdline"
                ];
              }
            ];
            outputs = [
              {
                name = "loki";
                host = "loki.service.byte-sized.fyi";
                port = 443;
                match = "comin";
                tls = "on";
                "tls.verify" = "on";
                labels = "job=comin,systemd_unit=$systemd_unit,hostname=$hostname";
              }
            ];
          };
          service.grace = 30;
        };
      };

      programs.git.enable = true;
      programs.git.config.safe.directory = "/home/emilia/nix-config";
    };
  };
}
