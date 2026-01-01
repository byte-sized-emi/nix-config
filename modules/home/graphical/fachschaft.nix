{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
  ];
  programs.ssh.enable = true;
  # programs.ssh.enableDefaultConfig = false;
  programs.ssh.extraConfig = ''
    Host fs-lab01
            HostName 10.19.5.111
            Port 22
            User root
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-lab02
            HostName 10.19.5.112
            Port 22
            User root
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-labbackup
    HostName 10.19.5.113
            Port 22
            User root
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-prod01
            HostName 10.19.5.104
            Port 22
            User root
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-prod02
            HostName 10.19.5.105
            Port 22
            User root
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-prodbackup
            HostName 10.19.5.106
            Port 22
            User root
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-gateway
            HostName 141.40.176.36
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey

    Host fs-ldap
    HostName 10.19.5.11
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-keycloak
            HostName 10.19.5.12
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-website
            HostName 10.19.5.25
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-webmail
            HostName 10.19.5.14
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-nextcloud
            HostName 10.19.5.15
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-wiki
            HostName 10.19.5.16
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-gitlab
            HostName 10.19.5.17
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-roomfinder
            HostName 10.19.5.18
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-nfs
            HostName 10.19.5.19
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-mail
            HostName 10.19.5.22
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-kasse
            HostName 10.19.5.27
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-infoscreen
            HostName 10.28.26.87
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey

    Host fs-zammad
            HostName 10.19.5.33
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-minecraft
            HostName 141.40.176.39
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey

    Host fs-kasse-scanner
            HostName 192.168.1.206
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey

    Host fs-matrix
            HostName 10.19.5.37
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway

    Host fs-forms
            HostName 10.19.5.35
            Port 22
            User fsadmin
            IdentityFile ~/.ssh/fs/hmKey
            ProxyJump fs-gateway
  '';

}
