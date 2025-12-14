{ settings, config, ... }:
{
  services.cloudflared.tunnels.${settings.ingress_tunnel}.ingress = {
    ${settings.secrets.domain} =
      "http://localhost:${toString config.services.vaultwarden.config.ROCKET_PORT}";
  };

  services.vaultwarden = {
    enable = true;
    # automatically backed up at 23:00 every day using backup-vaultwarden.{service/timer}
    backupDir = "/var/backup/vaultwarden";
    environmentFile = config.sops.secrets."vaultwarden/env".path;
    config = {
      DOMAIN = "https://${settings.secrets.domain}";
      SIGNUPS_ALLOWED = false;

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "info";

      SMTP_HOST = "smtp.migadu.com";
      SMTP_PORT = 465;
      SMTP_SECURITY = "force_tls";
      SMTP_USERNAME = "vaultwarden@${settings.domain}";
      SMTP_FROM = "vaultwarden@${settings.domain}";
      SMTP_FROM_NAME = "Bitwarden server";
    };
  };
}
