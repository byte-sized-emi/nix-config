{
  den.aspects.server-default.nixos = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      tmux
      kitty.terminfo
    ];
    documentation.nixos.enable = false;
  };
}
