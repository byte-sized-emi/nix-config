{
  den.aspects.server-default.nixos = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      tmux
      zellij
      kitty.terminfo
    ];
    documentation.nixos.enable = false;
  };
}
