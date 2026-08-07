{ inputs, lib, ... }:
{
  den.aspects.secrets =
    { user, ... }:
    let
      sopsConfig = {
        defaultSopsFile = ../secrets.yaml;
        age.keyFile = "/var/lib/sops-nix/key.txt";
      };
    in
    {
      homeManager = {
        imports = [ inputs.sops-nix.homeManagerModules.sops ];
        sops = sopsConfig;
      };
      nixos = {
        imports = [ inputs.sops-nix.nixosModules.sops ];
        sops = sopsConfig // {
          secrets =
            let
              userName = user.userName;
              userHome = "/home/${userName}";
              sshKeys = [
                "byte_sized"
                "github"
                "fachschaft"
                "lrz_gitlab"
              ];
              generateSshConfig = name: {
                "ssh_keys/${name}/pub" = {
                  owner = userName;
                  path = "${userHome}/.ssh/id_${name}.pub";
                };
                "ssh_keys/${name}/priv" = {
                  owner = userName;
                  path = "${userHome}/.ssh/id_${name}";
                };
              };
              sshSecrets = map generateSshConfig sshKeys;
            in
            lib.mkMerge (
              [
                {
                  "kube/config" = {
                    owner = userName;
                    path = "${userHome}/.kube/config";
                  };
                  "tailscale/auth_key".owner = "root";
                }
              ]
              ++ sshSecrets
            );
        };
      };
    };
}
