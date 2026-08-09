{
  den.aspects.gaming = {
    nixos = {
      # for slippi launcher
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [ dolphin-emu ];
    };
  };
}
