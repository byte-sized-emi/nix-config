{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "emilia";
    dataDir = "/home/emilia";
    settings = {
      devices = {
        fedora-pc.id = "LR5G66D-TYTMKG7-6JHBNTX-TG3P3GM-PAITEJH-C476R5I-5JWXYRC-6DUHNAF";
        nixlaptop.id = "MV53ZKH-6LZG4FC-PT5FADQ-6RIRJN7-KSSTVO3-IGQ332J-6B7LRQM-VLKQLA5";
        nixnest.id = "LKZAOQV-OYK3EKP-RI4C2RY-EAH4NB5-WAC3IZ5-B3PEJ5L-ADGT26C-SRGYCAW";
      };
      folders = {
        "Ablage" = {
          path = "/home/emilia/Ablage";
          devices = [
            "fedora-pc"
            "nixlaptop"
            "nixnest"
          ];
        };
      };
    };
  };
}
