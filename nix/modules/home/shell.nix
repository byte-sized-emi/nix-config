{

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    # presets = [ "bracketed-segments" ]; # enable on next home-manager version :(
  };

  programs.nushell = {
    enable = true;
    settings = {
      show_banner = false;
      completions.external = {
        enable = true;
        max_results = 200;
      };
    };
  };

  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
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

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    # enableNushellIntegration = true;
    git = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  programs.bat.enable = true;
}
