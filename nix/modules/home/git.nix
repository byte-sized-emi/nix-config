{ lib, pkgs, ... }:
{
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
}
