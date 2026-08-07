{
  den.aspects.fonts = {
    nixos = { pkgs, ... }: {
      fonts.packages = with pkgs; [
        noto-fonts
        hack-font
      ];

      fonts.fontconfig.defaultFonts = {
        monospace = [
          "Hack"
          "Noto Sans Mono"
        ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
      };
    };
    homeManager =
      { pkgs, ... }:
      {
        fonts.fontconfig.enable = true;
        home.packages = [
          pkgs.nerd-fonts.fira-code
        ];
      };
  };
}
