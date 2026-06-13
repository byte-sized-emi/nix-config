{ lib, pkgs, ... }:
{
  programs.ssh.settings = {
    "Host git.byte-sized.fyi" = {
      IdentityFile = "~/.ssh/id_byte_sized";
    };
    "Host git.fs.cs.hm.edu" = {
      IdentityFile = "~/.ssh/id_byte_sized";
    };
    "Host github.com" = {
      IdentityFile = "~/.ssh/id_github";
    };
    "Host gitlab.lrz.de" = {
      IdentityFile = "~/.ssh/id_lrz_gitlab";
    };
    "Host d0804253.repo.borgbase.com" = {
      IdentityFile = "~/.ssh/id_byte_sized";
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
        condition = "hasconfig:remote.*.url:https://git.fs.cs.hm.edu/**";
        contents = {
          user.name = "Emilia Jaser";
          user.email = "ejaser@fs.cs.hm.edu";
          user.signingKey = "~/.ssh/id_byte_sized";
        };
      }
      {
        condition = "hasconfig:remote.*.url:git@git.fs.cs.hm.edu:*/**";
        contents = {
          user.name = "Emilia Jaser";
          user.email = "ejaser@fs.cs.hm.edu";
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
      url."ssh://git@gitlab.lrz.de/" = {
        insteadOf = "https://gitlab.lrz.de/";
      };
    };
  };

  programs.git-credential-oauth.enable = true;
}
