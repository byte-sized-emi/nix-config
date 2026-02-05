{
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets =
      let
        inherit (config.users) users;
        sshKeys = [
          "byte_sized"
          "github"
          "fachschaft"
          "lrz_gitlab"
        ];
        generateSshConfig = name: {
          "ssh_keys/${name}/pub" = {
            owner = users.emilia.name;
            path = "${users.emilia.home}/.ssh/id_${name}.pub";
          };
          "ssh_keys/${name}/priv" = {
            owner = users.emilia.name;
            path = "${users.emilia.home}/.ssh/id_${name}";
          };
        };
        sshSecrets = map generateSshConfig sshKeys;
      in
      lib.mkMerge (
        [
          {
            "kube/config" = {
              owner = users.emilia.name;
              path = "${users.emilia.home}/.kube/config";
            };
            "tailscale/auth_key".owner = "root";
          }
        ]
        ++ sshSecrets
      );
  };
}
