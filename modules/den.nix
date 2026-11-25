{
  inputs,
  den,
  lib,
  ...
}:
{
  imports = [
    inputs.den.flakeModule
    (inputs.den.namespace "apps" false)
    (inputs.den.namespace "stacks" false)
  ];

  den.default.includes = [ den.aspects.per-system ];

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.hosts.x86_64-linux = {
    nixlaptop = {
      users.emilia = { };
    };
    nixda = {
      users.emilia = { };
    };
    nixnest = {
      users.emilia = { };
      ipv4 = "192.168.0.201";
    };
    nixdort = {
      users.emilia = { };
      ipv4 = "192.168.0.204";
    };
  };

  den.schema.host.includes = [
    den.batteries.user-aspects
    den.batteries.hostname
    den.aspects.boot
    den.aspects.nix-settings
    den.aspects.secrets
    den.aspects.tailscale
  ];

  # maybe add <den/host-aspects>?
  # https://den.denful.dev/reference/batteries/#denbatterieshost-aspects
  den.schema.user.includes = [
    den.batteries.define-user
    den.aspects.secrets
  ];

  den.aspects.emilia.includes = [
    den.batteries.primary-user
  ];
}
