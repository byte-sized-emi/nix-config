{ config, ... }:
let
  stackPath = "/var/stacks/atuin";
in
{
  my.services.atuin = {
    enable = true;
    port = config.services.atuin.port;
    description = "Shared shell history";
    internal.enable = true;
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath} 0770 root root"
  ];

  services.atuin = {
    enable = true;
    openRegistration = true;
    database = {
      createLocally = false;
      uri = "sqlite://${stackPath}/atuin.db";
    };
  };

  systemd.services.atuin.serviceConfig.ReadWritePaths = [ stackPath ];
}
