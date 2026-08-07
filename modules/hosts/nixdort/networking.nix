{
  den.aspects.nixdort.nixos = {
    networking = {
      useDHCP = false;
      interfaces = {
        enp5s0 = {
          ipv4.addresses = [
            {
              address = "192.168.0.204";
              prefixLength = 24;
            }
          ];
        };
        enp6s0 = {
          ipv4.addresses = [
            {
              address = "192.168.0.205";
              prefixLength = 24;
            }
          ];
        };
      };
      defaultGateway = "192.168.0.1";
    };
  };
}
