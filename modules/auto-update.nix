{ inputs, ... }:
{
  den.aspects.auto-update = {
    desktop.nixos = {
      services.comin = {
        desktop.enable = true;
        buildConfirmer.mode = "manual";
        deployConfirmer.mode = "manual";
      };
    };
    nixos =
      {
        http-services,
        pkgs,
        config,
        lib,
        ...
      }:
      let
        loki-service = builtins.head (builtins.filter (s: s.service_name == "loki") http-services);
        ntfy-service = builtins.head (builtins.filter (s: s.service_name == "ntfy") http-services);
      in
      {
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
                  ${ntfy-service.url}/deploys
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
                  host = loki-service.host;
                  port = loki-service.port;
                  match = "comin";
                  tls = if loki-service.https then "on" else "off";
                  "tls.verify" = if loki-service.https then "on" else "off";
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
