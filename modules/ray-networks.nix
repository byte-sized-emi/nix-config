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

  keygenScript =
    pkgs:
    let
      python = pkgs.python3.withPackages (ps: [ ps.pynacl ]);
    in
    ''
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
        head -c 32 /dev/urandom > "secret-key"
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
    nixos =
      { config, ... }:
      let
        networks = host.ray.networks;
        networksWithOperator = builtins.filter (net: net.operator or false) networks;
        networkIds = map (net: den.ray-networks.${net}.id) (lib.attrNames networks);
      in
      {
        services.rayfish = {
          enable = true;
          id = host.ray.id;
          secretFile = config.sops.secrets."rayfish/identities/${host.hostName}/secret-key";
          joinNetworks = networkIds;
        };
      };
  };

  config.den.ray-networks = {
    # TODO: put the actual network id in here
    core.id = "";
  };
}
