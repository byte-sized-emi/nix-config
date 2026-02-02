{ pkgs, config, ... }:
{
  users.groups.emilia = { };
  users.users.emilia = {
    isNormalUser = true;
    group = config.users.groups.emilia.name;
    extraGroups = [
      "wheel"
      "podman"
      "docker"
      "audio"
      "networkmanager"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      tree
      kanidm_1_8
      cloudflared
      bind
    ];
  };

  security.doas.enable = true;
  security.doas.extraRules = [
    {
      users = [ config.users.users.emilia.name ];
      keepEnv = true;
      persist = true;
    }
  ];

  programs.zsh.enable = true;
}
