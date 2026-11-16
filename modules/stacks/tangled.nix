{ inputs, ... }:
{
  # this isn't currently used - i probably need a way to proxy port 22 to my homelab
  # for this to make sense :/
  stacks.tangled.nixos = { config, ... }: {
    imports = [ inputs.tangled.nixosModules.knot-rs ];

    sops.secrets."tangled/knotMasterKey" = { };

    sops.templates."tangled/knot.env".content = ''
      KNOT_MASTER_KEY=${config.sops.placeholder."tangled/knotMasterKey"}
    '';

    services.tangled.knot-rs = {
      enable = true;
      environmentFile = config.sops.templates."tangled/knot.env".path;
      settings = {
        server = {
          hostname = "knot.byte-sized.fyi";
          admins = [ "did:plc:yourdid" ];
        };
        atproto.plc_directory = "https://plc.directory";
        lfs.store_path = "/var/lib/knot/lfs";
        contact.email = "your@contact.email";
      };
    };
  };
}
