{
  den.aspects.fachschaft = {
    nixos = { config, ... }: {
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
            mtu = "1280";
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
        FS04-Emilia-Jaser = {
          connection = {
            autoconnect = "false";
            id = "FS04-Emilia-Jaser";
            interface-name = "fs04-wg";
            type = "wireguard";
            uuid = "57612da5-0918-45d4-ba2a-8b5dae769566";
          };
          ipv4 = {
            address1 = "10.250.1.47/32";
            dns = "10.250.2.1;";
            dns-search = "~;";
            method = "manual";
          };
          ipv6 = {
            addr-gen-mode = "default";
            method = "disabled";
          };
          proxy = { };
          wireguard = {
            # mtu = "1450";
            private-key = "$FS04_WIREGUARD_PRIV_KEY";
          };
          "wireguard-peer.lpuTrQK9GORfse3Zh2z+cJ3NZUqOoSmvoZKqYR7xXnc=" = {
            allowed-ips = "10.50.0.0/24;10.250.0.0/16;10.27.0.0/16";
            # allowed-ips = "0.0.0.0/0";
            endpoint = "129.187.206.205:34966";
            persistent-keepalive = "15";
            preshared-key = "$FS04_WIREGUARD_PSK";
            preshared-key-flags = "0";
          };
        };
      };
    };
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          keepassxc
        ];

        home.shellAliases = {
          fsup = "nmcli con up FS-Emilia-Jaser";
          fsdown = "nmcli con down FS-Emilia-Jaser";
          fs07up = "nmcli con up FS-Emilia-Jaser";
          fs07down = "nmcli con down FS-Emilia-Jaser";
          fs04up = "nmcli con up FS04-Emilia-Jaser";
          fs04down = "nmcli con down FS04-Emilia-Jaser";
        };

        programs.ssh.enable = true;
        programs.ssh.enableDefaultConfig = false;

        programs.ssh.settings =
          let
            genPhysicalRoot = HostName: {
              inherit HostName;
              Port = 22;
              User = "root";
            };
            genDirect = HostName: {
              inherit HostName;
              Port = 22;
              User = "fsadmin";
              IdentityFile = "~/.ssh/fs/hmKey";
            };
            genViaGateway = HostName: {
              inherit HostName;
              Port = 22;
              User = "fsadmin";
              IdentityFile = "~/.ssh/fs/hmKey";
              ProxyJump = "fs-gateway";
            };
          in
          {
            "*" = { };

            # Physical systems sorted by IP
            fs-prod01 = genPhysicalRoot "10.19.5.104";
            fs-prod02 = genPhysicalRoot "10.19.5.105";
            fs-prodbackup = genPhysicalRoot "10.19.5.106";
            fs-lab01 = genPhysicalRoot "10.19.5.111";
            fs-lab02 = genPhysicalRoot "10.19.5.112";
            fs-labbackup = genPhysicalRoot "10.19.5.113";
            fs-heinl = genPhysicalRoot "10.19.5.114";
            fs-infoscreen-foyer = genDirect "10.28.26.87";

            # Public-IP-Only
            fs-minecraft = genDirect "141.40.176.39";
            fs-gitlab = genDirect "141.40.176.40";
            fs-kasse-scanner = genDirect "192.168.1.50";

            # Gateway
            fs-gateway = genDirect "141.40.176.36";

            # Normal VMs sorted by IP
            fs-ldap = genViaGateway "10.19.5.11";
            fs-keycloak = genViaGateway "10.19.5.12";
            fs-docker = genViaGateway "10.19.5.13";
            fs-webmail = genViaGateway "10.19.5.14";
            fs-spindverwaltung = genViaGateway "10.19.5.18";
            fs-nfs = genViaGateway "10.19.5.19";
            fs-mail = genViaGateway "10.19.5.22";
            fs-wiki = genViaGateway "10.19.5.23";
            fs-grist = genViaGateway "10.19.5.24";
            fs-helfertool = genViaGateway "10.19.5.25";
            fs-zammad = genViaGateway "10.19.5.33";
            fs-forms = genViaGateway "10.19.5.35";
            fs-matrix = genViaGateway "10.19.5.37";
            fs-monitoring = genViaGateway "10.19.5.39";
            fs-nextcloud = genViaGateway "10.19.5.43";
            fs-kasse = genViaGateway "10.19.5.46";
            fs-pretix = genViaGateway "10.19.5.47";
            fs-biernet = genViaGateway "10.19.5.48";
            fs-infoscreen-vm = genViaGateway "10.19.5.62";
          };
      };
  };
}
