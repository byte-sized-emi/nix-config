{ inputs, lib, ... }:
{
  den.aspects.rayfish.nixos =
    { config, pkgs, ... }:
    let
      cfg = config.services.rayfish;
    in
    {
      options.services.rayfish = {
        enable = lib.mkEnableOption "the Rayfish P2P mesh VPN daemon";

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.rayfish-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.rayfish;
          defaultText = lib.literalExpression ''
            inputs.rayfish-nixpkgs.legacyPackages.''${pkgs.stdenv.hostPlatform.system}.rayfish
          '';
          description = "The rayfish package providing the `ray` CLI and daemon.";
        };
        secretFile = lib.mkOption {
          type = lib.types.path;
          description = "File to the base64-encoded secret key for the Rayfish daemon.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ cfg.package ];

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
        };
      };
    };
}
