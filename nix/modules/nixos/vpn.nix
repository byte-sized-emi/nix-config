{ config, ... }:
{
  sops.secrets."networkManager.env" = { };
  networking.networkmanager.ensureProfiles.environmentFiles = [
    config.sops.secrets."networkManager.env".path
  ];

  networking.networkmanager.ensureProfiles.profiles = {
    FS-Emilia-Jaser = {
      connection = {
        autoconnect = "false";
        id = "FS-Emilia-Jaser";
        interface-name = "FS-Emilia-Jaser";
        type = "wireguard";
        uuid = "16545350-f877-43ed-b69d-c863ac380af4";
      };
      ipv4 = {
        address1 = "10.252.10.5/32";
        dns = "1.1.1.1;";
        dns-search = "~;";
        method = "manual";
      };
      ipv6 = {
        addr-gen-mode = "default";
        method = "disabled";
      };
      proxy = { };
      wireguard = {
        mtu = "1450";
        private-key = "$FS_WIREGUARD_PRIV_KEY";
      };
      "wireguard-peer.If3/NKCnOfdJZmZFCR/2GXVR1+sdEBJ1JaBEdeYE9Uo=" = {
        allowed-ips = "0.0.0.0/0;";
        endpoint = "141.40.176.36:51820";
        persistent-keepalive = "15";
        preshared-key = "$FS_WIREGUARD_PSK";
        preshared-key-flags = "0";
      };
    };
    airvpn = {
      connection = {
        autoconnect = "false";
        id = "airvpn";
        interface-name = "airvpn";
        timestamp = "1777292720";
        type = "wireguard";
        uuid = "5ec07844-d7d0-4ba5-987b-fb606114a376";
      };
      ipv4 = {
        address1 = "10.184.227.54/32";
        dns = "10.128.0.1;";
        dns-search = "~;";
        method = "manual";
      };
      ipv6 = {
        addr-gen-mode = "stable-privacy";
        address1 = "fd7d:76ee:e68f:a993:97b8:d95f:eb8a:8dea/128";
        dns = "fd7d:76ee:e68f:a993::1;";
        dns-search = "~;";
        method = "manual";
      };
      proxy = { };
      wireguard = {
        mtu = "1320";
        private-key = "$AIRVPN_WIREGUARD_PRIV_KEY";
      };
      "wireguard-peer.PyLCXAQT8KkM4T+dUsOQfn+Ub3pGxfGlxkIApuig+hk=" = {
        allowed-ips = "0.0.0.0/0;::/0;";
        endpoint = "europe3.vpn.airdns.org:1637";
        persistent-keepalive = "15";
        preshared-key = "$AIRVPN_WIREGUARD_PSK";
        preshared-key-flags = "0";
      };
    };
  };
}
