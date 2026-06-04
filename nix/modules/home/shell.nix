{
  home.shell.enableZshIntegration = true;

  # shell prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # presets = [ "bracketed-segments" ]; # enable on next home-manager version :(
  };

  # argument completion
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    autocd = true;
    # enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
      bindkey '^[[3;5~' kill-word
      bindkey '^H'      backward-kill-word
    '';
    shellAliases = {
      update = "nixos-rebuild switch --sudo";
      update-test = "nixos-rebuild test --sudo";
      ls = "eza";
      cat = "bat";
      # for opening a directory in the current zed window
      zopen = "zeditor -r";
      sops-zed = "EDITOR=\"zeditor --wait\" sops";
      sudo = "doas";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
    };
    history.append = true;
  };

  programs.direnv = {
    enable = true;
    silent = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # ls replacement
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
  };

  programs.atuin = {
    enable = true;
    flags = [
      "--disable-up-arrow"
      "--disable-ai"
    ];
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://atuin.service.byte-sized.fyi";
    };
  };

  programs.yazi = {
    enable = true;
    shellWrapperName = "z";
  };

  programs.bat.enable = true;
}
