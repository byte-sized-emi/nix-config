{
  services.nfs.settings = {
    nfsd = {
      vers2 = false;
      vers4 = true;
    };
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /export       100.64.0.0/10(rw,sync,fsid=root,no_subtree_check,insecure) fd7a:115c:a1e0::/48(rw,sync,fsid=root,no_subtree_check,insecure)
      /export/media 100.64.0.0/10(rw,sync,fsid=0,no_subtree_check,insecure) fd7a:115c:a1e0::/48(rw,sync,fsid=0,no_subtree_check,insecure)
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
