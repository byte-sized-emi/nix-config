{ config, inputs, ... }:
{
  imports = [ inputs.secret-nix-config.homeManagerModules.email ];
  sops.secrets."migaduPw" = { };
  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
    };
  };

  accounts.email.accounts = {
    byte-sized = {
      enable = true;
      primary = true;
      realName = "Emilia Jaser";
      address = "emilia@byte-sized.fyi";
      flavor = "migadu.com";
      aliases = [
        "admin@byte-sized.fyi"
      ];
      passwordCommand = "cat ${config.sops.secrets.migaduPw.path}";
      thunderbird.enable = false;
    };
    # hochschule = {
    #   enable = true;
    #   primary = false;
    #   realName = "Emilia Jaser";
    #   address = "emilia.jaser@hm.edu";
    #   flavor = "outlook.office365.com-ews";
    #   thunderbird.enable = true;
    # };
  };
}
