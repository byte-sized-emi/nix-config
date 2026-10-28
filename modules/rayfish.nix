{ inputs, lib, ... }:
{
  den.aspects.rayfish.nixos =
    { config, pkgs, ... }:
    let
      cfg = config.services.rayfish;
      listenPort = 41383;

      # Networks this host coordinates (its network secret is known here) and
      # those it only joins as a peer.
      coordinated = lib.filterAttrs (_: net: net.secretFile != null) cfg.networks;
      joined = lib.filterAttrs (_: net: net.secretFile == null && net.roomId != null) cfg.networks;

      seedIdentity = pkgs.writeShellApplication {
        name = "rayfish-seed-identity";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          if [ -s /etc/rayfish/secret_key ]; then
            echo "/etc/rayfish/secret_key already exists, keeping it"
            exit 0
          fi

          tmp=$(mktemp)
          trap 'rm -f "$tmp"' EXIT
          base64 -d ${lib.escapeShellArg (toString cfg.secretFile)} > "$tmp"

          install -d -m 0750 /etc/rayfish
          install -m 0600 "$tmp" /etc/rayfish/secret_key
        '';
      };

      # The daemon restores any saved network holding the network secret key as
      # coordinator and republishes its roster, so a seeded config is all a
      # coordinator needs.
      seedNetworks = pkgs.writeShellApplication {
        name = "rayfish-seed-networks";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          install -d -m 0750 /etc/rayfish /etc/rayfish/networks
          umask 077

          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: net: ''
              cfg=/etc/rayfish/networks/${name}.toml
              if [ ! -f "$cfg" ]; then
                key_hex=$(base64 -d ${lib.escapeShellArg (toString net.secretFile)} | od -A n -t x1 -v | tr -d ' \n')
                printf 'name = "%s"\ngroup_mode = "%s"\nmy_hostname = "%s"\nnetwork_secret_key = "%s"\n' \
                  ${lib.escapeShellArg name} ${
                    if net.open then "open" else "restricted"
                  } ${lib.escapeShellArg config.networking.hostName} "$key_hex" > "$cfg"
              fi
            '') coordinated
          )}
        '';
      };

      # Joining a restricted network only queues a request; the daemon keeps it
      # pending and retries until the coordinator runs `ray accept`.
      joinNetworks = pkgs.writeShellApplication {
        name = "rayfish-join-networks";
        runtimeInputs = [
          cfg.package
          pkgs.coreutils
          pkgs.jq
        ];
        text = ''
          for _ in $(seq 1 60); do
            [ -S /run/rayfish/rayfish.sock ] && break
            sleep 1
          done

          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: net: ''
              if ray status --json | jq -e --arg n ${lib.escapeShellArg name} \
                '[(.networks // [])[], (.inactive_networks // [])[]] | map(.name) | index($n)' > /dev/null; then
                echo "already a member of ${name}"
              else
                ray join ${lib.escapeShellArg net.roomId} --name ${lib.escapeShellArg name} --hostname ${lib.escapeShellArg config.networking.hostName}
              fi
            '') joined
          )}
        '';
      };
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
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            File containing the base64-encoded 32-byte secret key of this
            machine's identity. It is decoded once into
            `/etc/rayfish/secret_key`; an existing key is never overwritten.
            When null, the daemon generates its own identity on first start.
          '';
        };
        networks = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                secretFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = ''
                    File containing the network's base64-encoded secret key.
                    When set, this host seeds `/etc/rayfish/networks/<name>.toml`
                    and coordinates the network.
                  '';
                };
                roomId = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = ''
                    Public room id to join this network with when the network
                    secret key is not known here. The join has to be approved
                    once on the coordinator with `ray accept <name> <id>`.
                  '';
                };
                open = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Coordinate the network as open instead of restricted.";
                };
              };
            }
          );
          default = { };
          description = "Rayfish networks this machine is a member of.";
        };
        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to open UDP port ${toString listenPort} for direct peer
            connections. iroh relays still provide connectivity when this is
            closed, so direct peering is only an optimisation.
          '';
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          environment.systemPackages = [ cfg.package ];

          # The daemon opens /dev/net/tun and drives the interface itself.
          boot.kernelModules = [ "tun" ];
          networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ listenPort ];

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
        })

        (lib.mkIf (cfg.enable && cfg.secretFile != null) {
          systemd.services.rayfish-seed-identity = {
            description = "Seed the Rayfish identity key before first start";
            wantedBy = [ "multi-user.target" ];
            before = [ "rayfish.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = lib.getExe seedIdentity;
            };
          };

          systemd.services.rayfish = {
            requires = [ "rayfish-seed-identity.service" ];
            after = [ "rayfish-seed-identity.service" ];
          };
        })

        (lib.mkIf (cfg.enable && coordinated != { }) {
          systemd.services.rayfish-seed-networks = {
            description = "Seed the Rayfish coordinator network configs before first start";
            wantedBy = [ "multi-user.target" ];
            before = [ "rayfish.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = lib.getExe seedNetworks;
            };
          };

          systemd.services.rayfish = {
            requires = [ "rayfish-seed-networks.service" ];
            after = [ "rayfish-seed-networks.service" ];
          };
        })

        (lib.mkIf (cfg.enable && joined != { }) {
          systemd.services.rayfish-join = {
            description = "Ask to join the Rayfish networks this host is not a member of yet";
            wantedBy = [ "multi-user.target" ];
            requires = [ "rayfish.service" ];
            after = [ "rayfish.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = lib.getExe joinNetworks;
              Restart = "on-failure";
              RestartSec = 30;
            };
          };
        })
      ];
    };
}
