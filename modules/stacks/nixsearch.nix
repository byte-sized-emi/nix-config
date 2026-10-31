{
  stacks.nixsearch.nixos =
    let
      port = 3456;
      stackPath = "/var/stacks/nixsearch";
      configPath = "/etc/stacks/nixsearch/nixsearch.toml";
    in
    {
      my.services.nixsearch = {
        enable = true;
        name = "nixsearch";
        inherit port;
        description = "Search engine for Nix packages and options";
        internal.enable = true;
      };

      environment.etc."stacks/nixsearch/nixsearch.toml".text = ''
        [server]
        # Builds the first index on startup; /data is populated afterwards.
        bootstrap = true

        [server.schedule]
        enabled = true
        interval = "24h"

        [maintenance.index_generations]
        keep = 2
        delete_failed_after = "24h"

        [ref_sets.unstable]
        nixpkgs = ["nixos-unstable"]
        nixos = ["nixos-unstable"]
        home-manager = ["master"]

        [sources.nixpkgs]
        preset = "nixpkgs-packages"
        default_ref = "nixos-unstable"
        preset_refs = ["nixos-unstable"]

        [sources.nixos]
        preset = "nixos-options"
        default_ref = "nixos-unstable"
        preset_refs = ["nixos-unstable"]

        [sources.home-manager]
        preset = "home-manager-options"
        default_ref = "master"
        preset_refs = ["master"]
      '';

      systemd.tmpfiles.rules = [
        "d ${stackPath} 0750 root root -"
        # TMPDIR=/data/tmp is baked into the image and must already exist.
        "d ${stackPath}/tmp 0750 root root -"
      ];

      virtualisation.quadlet.containers.nixsearch = {
        containerConfig = {
          image = "ghcr.io/benkoppe/nixsearch-with-nix:main@sha256:ffe1ef955ddceebb4cdbdf3f8e9b962d81861b89a6ef8f0ff4d81a9a283891ca";
          memory = "2g";
          publishPorts = [ "127.0.0.1:${toString port}:3000" ];
          volumes = [
            "${configPath}:${configPath}:ro"
            "${stackPath}:/data"
          ];
          environments = {
            NIXSEARCH_CONFIG = configPath;
            RUST_LOG = "info";
          };
        };
        serviceConfig = {
          Restart = "always";
          CPUQuota = "100%";
        };
      };
    };
}
