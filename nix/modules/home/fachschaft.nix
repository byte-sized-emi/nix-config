{ pkgs, ... }:
{
  home.packages = with pkgs; [
    keepassxc
  ];
  programs.ssh.enable = true;
  programs.ssh.enableDefaultConfig = false;

  # TODO: Improve me
  # - add key to sops-nix
  # - make this config smaller and more nix-ified

  programs.ssh.settings =
    let
      genHostRoot = HostName: {
        inherit HostName;
        Port = 22;
        User = "root";
        IdentityFile = "~/.ssh/fs/hmKey";
        ProxyJump = "fs-gateway";
      };
      genHost = HostName: {
        inherit HostName;
        Port = 22;
        User = "fsadmin";
        IdentityFile = "~/.ssh/fs/hmKey";
        ProxyJump = "fs-gateway";
      };
      genHostDirect = HostName: {
        inherit HostName;
        Port = 22;
        User = "fsadmin";
        IdentityFile = "~/.ssh/fs/hmKey";
      };
    in
    {
      "*" = { };

      fs-gateway = genHostDirect "141.40.176.36";

      # root user
      fs-lab01 = genHostRoot "10.19.5.111";
      fs-lab02 = genHostRoot "10.19.5.112";
      fs-labbackup = genHostRoot "10.19.5.113";
      fs-prod01 = genHostRoot "10.19.5.104";
      fs-prod02 = genHostRoot "10.19.5.105";
      fs-prodbackup = genHostRoot "10.19.5.106";

      # fsadmin user
      fs-forms = genHost "10.19.5.35";
      fs-gitlab = genHost "10.19.5.17";
      fs-kasse = genHost "10.19.5.27";
      fs-keycloak = genHost "10.19.5.12";
      fs-ldap = genHost "10.19.5.11";
      fs-mail = genHost "10.19.5.22";
      fs-matrix = genHost "10.19.5.37";
      fs-nextcloud = genHost "10.19.5.15";
      fs-nfs = genHost "10.19.5.19";
      fs-roomfinder = genHost "10.19.5.18";
      fs-webmail = genHost "10.19.5.14";
      fs-website = genHost "10.19.5.25";
      fs-wiki = genHost "10.19.5.16";
      fs-zammad = genHost "10.19.5.33";

      # direct connections, without gateway
      fs-infoscreen = genHostDirect "10.28.26.87";
      fs-kasse-scanner = genHostDirect "192.168.1.206";
      fs-minecraft = genHostDirect "141.40.176.39";
    };
}
