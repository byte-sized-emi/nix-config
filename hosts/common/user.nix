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
      kanidm_1_7
      cloudflared
      bind
    ];
  };

  programs.zsh.enable = true;
}
