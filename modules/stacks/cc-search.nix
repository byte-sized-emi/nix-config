{ inputs, ... }:
{
  stacks.cc-search.nixos = { config, ... }: {
    imports = [ inputs.cc-search.nixosModules.default ];

    services.cc-search = {
      enable = true;
      folder = "/var/stacks/cc-search/subtitles";
      port = 8238;
    };

    my.services.cc-search = {
      enable = true;
      port = config.services.cc-search.port;
      description = "code culture search engine";
      internal.enable = true;
    };
  };
}
