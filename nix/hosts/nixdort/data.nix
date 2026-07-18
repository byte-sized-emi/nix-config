{
  services.nfs.server = {
    enable = true;
    exports = ''
      /mnt/media 100.64.0.0/10(rw,sync,fsid=0,no_subtree_check) fd7a:115c:a1e0::/48(rw,sync,fsid=0,no_subtree_check)
    '';
  };

  users.users.media = {
    uid = 311;
    group = "media";
  };

  users.groups.media = {
    gid = 311;
    members = [
      "media"
      "emilia"
    ];
  };
}
