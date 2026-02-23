{ ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      download-buffer-size = 524288000; # 500 MiB
      substituters = [
        "https://vicinae.cachix.org"
        "https://hyprland.cachix.org"
        "https://niri.cachix.org"
      ];
      trusted-public-keys = [
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
