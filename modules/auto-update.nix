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
    nixos = { config, ... }: {
      imports = [ inputs.comin.nixosModules.comin ];

      sops.secrets."comin-access-token" = { };

      services.comin = {
        enable = true;
        submodules = true;
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

      programs.git.enable = true;
      programs.git.config.safe.directory = "/home/emilia/nix-config";
    };
  };
}
