{
  inputs,
  den,
  lib,
  __findFile,
  ...
}:
{
  # angle brackets syntax
  _module.args.__findFile = den.lib.__findFile;

  imports = [
    inputs.den.flakeModule
    (inputs.den.namespace "apps" false)
    (inputs.den.namespace "stacks" false)
  ];

  den.default.includes = [ <per-system> ];

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.hosts.x86_64-linux = {
    nixlaptop = {
      role = "desktop";
      users.emilia = { };
    };
    nixda = {
      role = "desktop";
      users.emilia = { };
    };
    nixnest = {
      role = "server";
      users.emilia = { };
      ipv4 = "192.168.0.201";
    };
    nixdort = {
      role = "server";
      users.emilia = { };
      ipv4 = "192.168.0.204";
    };
  };

  den.schema.host.includes = [
    <boot>
    <den/hostname>
    <nix-settings>
    <secrets>
    <tailscale>
  ];

  # maybe add <den/host-aspects>?
  # https://den.denful.dev/reference/batteries/#denbatterieshost-aspects
  den.schema.user.includes = [
    <den/define-user>
    <secrets>
  ];

  den.aspects.emilia.includes = [
    <den/primary-user>
  ];
}
