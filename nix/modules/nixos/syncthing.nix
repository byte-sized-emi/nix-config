{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "emilia";
    dataDir = "/home/emilia";
    settings = {
      devices = {
        nixlaptop.id = "MV53ZKH-6LZG4FC-PT5FADQ-6RIRJN7-KSSTVO3-IGQ332J-6B7LRQM-VLKQLA5";
        nixnest.id = "LKZAOQV-OYK3EKP-RI4C2RY-EAH4NB5-WAC3IZ5-B3PEJ5L-ADGT26C-SRGYCAW";
        nixda.id = "DY3BTNR-TBT7W42-CP6Y5VQ-Q3DL3AV-PFPDKUU-TMR5A53-GAYK5QD-7KOGDA4";
      };
      folders = {
        "Ablage" = {
          path = "/home/emilia/Ablage";
          devices = [
            "nixlaptop"
            "nixnest"
            "nixda"
          ];
        };
      };
    };
  };
}
