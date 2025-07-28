{ config, pkgs, ... }:

{
  home.username = "emi";
  home.homeDirectory = "/home/emi";

  programs.git = {
    enable = true;
    userName = "Emilia Jaser";
    userEmail = "vapor.schitcrafter@gmail.com";
    # git config credential.helper store
    extraConfig = {
      credential.helper = "store";
    };
  };

  programs.starship = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
        update = "nixos-rebuild switch --use-remote-sudo";
    };
  };

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}
