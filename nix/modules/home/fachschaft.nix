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
}
