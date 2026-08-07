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
  ];

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.hosts.x86_64-linux.nixlaptop.users.emilia = { };
  den.hosts.x86_64-linux.nixda.users.emilia = { };

  # den.hosts.x86_64-linux.nixnest.users.emilia = { };

  den.schema.host.includes = [
    <boot>
    <den/hostname>
    <nix-settings>
    <secrets>
    <tailscale>
  ];

  den.schema.user.includes = [
    <den/define-user>
    <secrets>
  ];

  den.aspects.emilia.includes = [
    <den/primary-user>
  ];
}
