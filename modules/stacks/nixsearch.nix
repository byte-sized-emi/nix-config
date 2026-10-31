{
  inputs,
  ...
}:
{
  stacks.nixsearch.nixos =
    { pkgs, ... }:
    let
      port = 3456;
      stackPath = "/var/stacks/nixsearch";
      configPath = "/etc/stacks/nixsearch/nixsearch.toml";
      # den is indexed from a prebuilt options.json: its nixModule is a function of
      # `inputs` returning a module function, and evalModules only applies one level,
      # so both applications have to happen here.
      denOptionsJson =
        (pkgs.nixosOptionsDoc {
          options =
            (pkgs.lib.evalModules {
              specialArgs = {
                inherit pkgs inputs;
              };
              modules = [
                (args: inputs.den.nixModule inputs args)
                ({ lib, ... }: {
                  config._module.check = false;
                })
              ];
            }).options.den;
          warningsAreErrors = false;
        }).optionsJSON;
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
        den = ["main"]

        [sources.den]
        name = "Den"
        kind = "options"
        color = "#f472b6"

        [sources.den.refs.main.source_links]
        type = "github"
        owner = "denful"
        repo = "den"
        # the exact den revision the options.json was built from
        revision = "${inputs.den.sourceInfo.rev or "main"}"
        strip_prefixes = ["den"]

        [sources.den.refs.main.producer]
        type = "existing-file"
        path = "/etc/nixsearch/den-options.json"
        artifact = "options-json"

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
        # TMPDIR/HOME point inside /data and must already exist.
        "d ${stackPath}/tmp 0750 root root -"
        "d ${stackPath}/home 0750 root root -"
      ];

      virtualisation.quadlet.containers.nixsearch = {
        containerConfig = {
          image = "ghcr.io/benkoppe/nixsearch-with-nix:main@sha256:ffe1ef955ddceebb4cdbdf3f8e9b962d81861b89a6ef8f0ff4d81a9a283891ca";
          memory = "2g";
          publishPorts = [ "127.0.0.1:${toString port}:3000" ];
          volumes = [
            "${configPath}:${configPath}:ro"
            "${denOptionsJson}/share/doc/nixos/options.json:/etc/nixsearch/den-options.json:ro"
            "${stackPath}:/data"
          ];
          environments = {
            NIXSEARCH_CONFIG = configPath;
            # nix needs an absolute cache dir; unset HOME breaks every flake fetch
            # with "not an absolute path: .cache/nix".
            HOME = "/data/home";
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
