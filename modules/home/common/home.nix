{ pkgs, ... }:
{
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
  ];

  programs.git = {
    package = pkgs.gitFull;
    enable = true;
    signing = {
      signByDefault = true;
      format = "ssh";
    };
    includes = [
      {
        condition = "hasconfig:remote.origin.url:https://git.byte-sized.fyi/**";
        contents = {
          user.signingKey = "~/.ssh/id_byte_sized";
        };
      }
    ];
    settings = {
      init.defaultBranch = "main";
      user.name = "Emilia Jaser";
      user.email = "vapor.schitcrafter@gmail.com";
      push = {
        autoSetupRemote = true;
      };
    };
  };

  programs.git-credential-oauth.enable = true;

  programs.starship.enable = true;

  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      update = "nixos-rebuild switch --sudo";
      update-test = "nixos-rebuild test --sudo";
      ls = "eza";
      cat = "bat";
      # for opening a directory in the current zed window
      zopen = "zeditor -r";
      sops-zed = "EDITOR=\"zeditor --wait\" sops";
      sudo = "doas";
    };
  };

  programs.direnv = {
    enable = true;
    silent = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.bat.enable = true;

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}
