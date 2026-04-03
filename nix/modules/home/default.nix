{
  lib,
  pkgs,
  perSystem,
  ...
}:
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
    perSystem.isd.default
    borgbackup
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

  programs.ssh.matchBlocks = {
    "git.byte-sized.fyi" = {
      identityFile = "~/.ssh/id_byte_sized";
    };
    "github.com" = {
      identityFile = "~/.ssh/id_github";
    };
    "gitlab.lrz.de" = {
      identityFile = "~/.ssh/id_lrz_gitlab";
    };
    "d0804253.repo.borgbase.com" = {
      identityFile = "~/.ssh/id_byte_sized";
    };
  };

  programs.git = {
    package = pkgs.gitFull;
    enable = true;
    includes = [
      {
        condition = "hasconfig:remote.*.url:https://git.byte-sized.fyi/**";
        contents = {
          user.signingKey = "~/.ssh/id_byte_sized";
        };
      }
      {
        condition = "hasconfig:remote.*.url:git@github.com:*/**";
        contents = {
          user.signingKey = "~/.ssh/id_github";
        };
      }
      {
        condition = "hasconfig:remote.*.url:git@gitlab.lrz.de:*/**";
        contents = {
          user.name = "Emilia Jaser";
          user.email = "emilia.jaser@hm.edu";
          user.signingkey = "~/.ssh/id_lrz_gitlab";
        };
      }
    ];
    signing = {
      signByDefault = true;
      format = "ssh";
    };
    settings = {
      init.defaultBranch = "main";
      user.name = "byte-sized-emi";
      user.email = "emilia.git@byte-sized.fyi";
      push.autoSetupRemote = true;
      credential.helper = lib.mkBefore [
        "cache --timeout 172800"
      ];
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
