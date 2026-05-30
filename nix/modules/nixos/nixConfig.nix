{ config, ... }:
{
  sops.secrets.nixAccessTokens = {
    mode = "0440";
    group = config.users.groups.keys.name;
  };

  # if you add a cache here, also add it to the update.yaml forgejo action
  nix = {
    settings = {
      warn-dirty = false;
      download-buffer-size = 524288000; # 500 MiB
      max-substitution-jobs = 128;
      http-connections = 128;
      max-jobs = "auto";
      substituters = [
        "https://niri.cachix.org"
      ];
      trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    # so nix can clone the secret-nix-config input without requiring interaction
    extraOptions = "!include ${config.sops.secrets.nixAccessTokens.path}";
  };
}
