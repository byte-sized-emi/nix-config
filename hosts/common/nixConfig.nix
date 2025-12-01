{ ... }:
{
  nix = {
    settings = {
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
    };
    extraOptions = ''
      # Ensure we can still build when a binary cache is not accessible
      fallback = true
    '';
  };
}
