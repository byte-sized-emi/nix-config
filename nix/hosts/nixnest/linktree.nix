{ perSystem, config, ... }:
{
  services.caddy.virtualHosts."linktree.${config.settings.services.domain}".extraConfig = ''
    encode
    root * ${perSystem.self.linktree}
    file_server
  '';
}
