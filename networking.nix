{ config, settings, ... }:

{
  users.users.cloudflared = {};
  # systemd service name: cloudflared-tunnel-584cad0d-c212-4156-a86e-ba1b4d157938
  services.cloudflared = {
    enable = true;
    tunnels."584cad0d-c212-4156-a86e-ba1b4d157938" = {
      credentialsFile = "/var/cloudflare-creds/b68b3740-8dc9-4136-aa64-bf1ed77d4886.json";
      default = "http_status:404";
      ingress = {
        "sso.byte-sized.fyi" = "https://localhost:8443";
      };
    };
  };
}
