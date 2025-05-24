{ config, settings, ... }:

{
  users.groups.cloudflared = {};
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };

  # systemd service name: cloudflared-tunnel-b68b3740-8dc9-4136-aa64-bf1ed77d4886
  services.cloudflared = {
    enable = true;
    tunnels."b68b3740-8dc9-4136-aa64-bf1ed77d4886" = {
      credentialsFile = "/var/cloudflare-creds/b68b3740-8dc9-4136-aa64-bf1ed77d4886.json";
      default = "http_status:404";
      originRequest.originServerName = settings.sso.domain;
      ingress = {
        "sso.byte-sized.fyi" = "https://localhost:8443";
      };
    };
  };
}
