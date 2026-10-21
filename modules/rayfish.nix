{ inputs, lib, ... }:
{
  den.aspects.rayfish.nixos =
    { config, pkgs, ... }:
    let
      cfg = config.services.rayfish;
      settingsFile = (pkgs.formats.toml { }).generate "rayfish-settings.toml" cfg.settings;
      specFile = (pkgs.formats.yaml { }).generate "rayfish-deploy.yaml" cfg.spec;
    in
    {
      options.services.rayfish = {
        enable = lib.mkEnableOption "the Rayfish P2P mesh VPN daemon";

        package = lib.mkOption {
          type = lib.types.package;
          default =
            inputs.rayfish-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.rayfish;
          defaultText = lib.literalExpression ''
            inputs.rayfish-nixpkgs.legacyPackages.''${pkgs.stdenv.hostPlatform.system}.rayfish
          '';
          description = "The rayfish package providing the `ray` CLI and daemon.";
        };

        settings = lib.mkOption {
          type = (pkgs.formats.toml { }).type;
          default = { };
          description = ''
            Global daemon settings, written to `/etc/rayfish/settings.toml`.
            This is the whole file: keys left out fall back to their defaults,
            including ones changed imperatively with `ray config set`.
            https://rayfish.xyz/docs/12-configuration
          '';
          example = {
            default_hostname = "build-box";
            operator_uid = 1000;
          };
        };

        spec = lib.mkOption {
          type = lib.types.nullOr (pkgs.formats.yaml { }).type;
          default = null;
          description = ''
            Deploy spec reconciled with `ray apply` on every daemon start, so
            networks, membership, suggested firewall rules and mesh SSH grants
            follow the config instead of `ray invite`/`ray firewall`/`ray ssh`.
            https://rayfish.xyz/docs/07-declarative-provisioning
          '';
          example = {
            networks.mesh."*".allows."*" = "tcp:22";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ cfg.package ];

        environment.etc."rayfish/settings.toml" = lib.mkIf (cfg.settings != { }) {
          source = settingsFile;
          mode = "0600";
        };

        systemd.services.rayfish = {
          description = "Rayfish P2P mesh VPN";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [
            "network-pre.target"
            "network-online.target"
            "NetworkManager.service"
            "systemd-resolved.service"
          ];
          serviceConfig = {
            ExecStart = "${cfg.package}/bin/ray daemon";
            ExecStopPost = "-${cfg.package}/bin/ray daemon --cleanup";
            Restart = "on-failure";
            RestartSec = 5;
            TimeoutStopSec = 20;
            LogsDirectory = "rayfish";
          };
          restartTriggers = lib.mkIf (cfg.settings != { }) [ settingsFile ];
        };

        systemd.services.rayfish-apply = lib.mkIf (cfg.spec != null) {
          description = "Reconcile Rayfish networks against the deploy spec";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "rayfish.service" "network-online.target" ];
          requires = [ "rayfish.service" ];
          partOf = [ "rayfish.service" ];
          # The daemon may not listen yet, or the network may still be down:
          # keep retrying instead of leaving the spec unapplied for the boot.
          unitConfig.StartLimitIntervalSec = 0;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = 15;
            ExecStart = "${cfg.package}/bin/ray apply ${specFile}";
          };
        };
      };
    };
}
