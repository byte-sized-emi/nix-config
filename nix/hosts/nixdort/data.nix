{
  services.nfs.settings = {
    nfsd = {
      vers2 = false;
      vers4 = true;
    };
  };

  services.nfs.server = {
    enable = true;
    exports =
    let
      # insecure means "allow non-privileged source ports"
      defaultOptions = "rw,sync,no_subtree_check,insecure";
      mediaOptions = "${defaultOptions},all_squash,anonuid=311,anongid=311";
    in ''
      /export       100.64.0.0/10(${defaultOptions},fsid=root) fd7a:115c:a1e0::/48(${defaultOptions},fsid=root)
      /export/media 100.64.0.0/10(${mediaOptions},fsid=2) fd7a:115c:a1e0::/48(${mediaOptions},fsid=2)
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
