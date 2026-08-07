{
  den.aspects.server-default.nixos = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      tmux
    ];
  };
}
