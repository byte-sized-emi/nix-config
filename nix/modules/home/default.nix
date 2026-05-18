{
  pkgs,
  perSystem,
  ...
}:
{
  imports = [
    ./git.nix
    ./shell.nix
  ];

  home.username = "emilia";
  home.homeDirectory = "/home/emilia";

  home.packages = with pkgs; [
    tree
    openssl
    htop
    btop
    bottom
    age
    sops
    nixd
    nil
    usbutils
    libargon2
    perSystem.isd.default
    borgbackup
    wl-clipboard-rs
  ];

  home.file.".config/isd_tui/config.yaml" = {
    text = ''
      # yaml-language-server: $schema=schema.json

      ## The systemctl startup mode (`user`/`system`).
      ## By default loads the mode from the last session (`auto`).
      startup_mode: "system"

      theme: "rose-pine"
    '';
  };

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}
