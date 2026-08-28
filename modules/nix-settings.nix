{
  den.aspects.nix-settings.nixos = {
    # if you add a cache here, also add it to the update.yaml forgejo action
    nix = {
      settings = {
        auto-optimise-store = true;
        warn-dirty = false;
        download-buffer-size = 524288000; # 500 MiB
        max-substitution-jobs = 128;
        http-connections = 128;
        max-jobs = "auto";
        trusted-users = [ "@wheel" ];
        substituters = [
          "https://niri.cachix.org"
          "https://cache.numtide.com"
        ];
        trusted-public-keys = [
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
    };
  };
}
