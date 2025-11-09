{ pkgs, config, ... }:
{
  users.groups.emilia = {};
  users.users.emilia = {
    isNormalUser = true;
    group = config.users.groups.emilia.name;
    extraGroups = [ "wheel" "podman" "audio" "networkmanager" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      tree
      kanidm_1_7
      cloudflared
    ];
  };

  programs.zsh.enable = true;
}
