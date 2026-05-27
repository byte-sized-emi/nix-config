{ config, lib, ... }:
let
  stackPath = "/var/stacks/atuin";
  user = config.users.users.atuin.name;
  group = config.users.groups.atuin.name;
in
{
  my.services.atuin = {
    enable = true;
    port = config.services.atuin.port;
    description = "Shared shell history";
    internal.enable = true;
    createSystemUser = true;
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath} 0770 ${user} ${group}"
  ];

  services.atuin = {
    enable = true;
    openRegistration = true;
    database = {
      createLocally = false;
      uri = "sqlite://${stackPath}/atuin.db";
    };
  };

  systemd.services.atuin.serviceConfig = {
    ReadWritePaths = [ stackPath ];
    DynamicUser = lib.mkForce false;
    User = user;
    Group = group;
  };
}
