{ lib, den, ... }:
let
  inherit (lib) mkOption types;

  # Derive the hex public key (iroh EndpointId) from a raw 32-byte secret key
  # file. Pure computation, so generators run fine in the default sandbox.
  keygenPy =
    pkgs:
    pkgs.writeText "rayfish-keygen.py" ''
      import sys

      import nacl.signing

      seed = open(sys.argv[1], "rb").read()
      print(nacl.signing.SigningKey(seed).verify_key.encode().hex())
    '';
in
{
  config.den.schema.ray-networks = {
    inherits = [ den.schema.conf ];
    options = {
      id = mkOption {
        type = types.str;
      };
    };
  };

  options.den.ray-networks = lib.mkOption {
    type = lib.types.attrsOf (
      den.lib.schema.mkInstanceType {
        strict = den.schema.ray-networks.isStrict;
      } den.schema.ray-networks
    );
  };

  config.den.aspects.rayfish-generate.packages = { pkgs, ... }: {
    rayfish-generate = pkgs.writeShellApplication {
      name = "rayfish-generate";
      runtimeInputs = [ (pkgs.python3.withPackages (ps: [ ps.pynacl ])) ];
      text = ''
        head -c 32 /dev/random > "secret-key"
        python3 ${keygenPy pkgs} "secret-key" > "id"
        base64 -w 0 "secret-key" > "secret-key.b64"
        rm secret-key
        echo "Generated 'secret-key.b64' and 'id' in this directory."
        echo "Public id (for modules/den.nix): $(cat id)"
        echo "Secret key (for secrets.yaml): $(cat secret-key.b64)"
      '';
      meta = {
        description = ''
          Generator script shared by the identity and network key generators:
          a raw 32-byte secret key plus its public hex id.
        '';
        mainProgram = "rayfish-generate";
      };
    };
  };

  config.den.aspects.ray-networks = { host, ... }: {
    # The rayfish options live in the rayfish aspect; pull it in so a host only
    # has to include ray-networks.
    includes = [ den.aspects.rayfish ];

    nixos =
      { config, ... }:
      let
        networks = host.ray.networks;
        identitySecret = "rayfish/identities/${host.hostName}/secret-key";
        networkSecret = name: "rayfish/networks/${name}/secret-key";
        hasSecret = host.ray.hasSecret or false;
      in
      {
        # Only hosts whose identity / network secret lives in secrets.yaml get
        # it seeded; everyone else runs with what it already has on disk.
        sops.secrets = lib.mkMerge [
          (lib.mkIf hasSecret { ${identitySecret} = { }; })
          (lib.mapAttrs' (
            name: net: lib.nameValuePair (networkSecret name) (lib.mkIf (net.operator or false) { })
          ) networks)
        ];

        services.rayfish = {
          enable = true;
          secretFile = lib.mkIf hasSecret config.sops.secrets.${identitySecret}.path;
          networks = lib.mapAttrs (name: net: {
            open = net.open or false;
            roomId = den.ray-networks.${name}.id;
            secretFile = lib.mkIf (net.operator or false) config.sops.secrets.${networkSecret name}.path;
          }) networks;
        };
      };
  };

  config.den.ray-networks = {
    core.id = "a95d0d38f538157e1b1b5463320506a1feee724a7829782cec2585e9a81515a5";
  };
}
