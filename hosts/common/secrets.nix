{ inputs, config, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets =
      let
        inherit (config.users) users;
      in
      {
        "kube/config" = {
          owner = users.emilia.name;
          path = "${users.emilia.home}/.kube/config";
        };
        "tailscale/auth_key".owner = "root";
      };
  };
}
