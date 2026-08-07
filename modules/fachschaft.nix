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
      };
    };
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          keepassxc
        ];
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
            fs-infoscreen-vm = genViaGateway "10.19.5.62";
          };
      };
  };
}
