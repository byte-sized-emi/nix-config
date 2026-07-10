{
  services.fluent-bit = {
    enable = true;
    settings = {
      pipeline = {
        inputs = [
          {
            name = "node_exporter";
            tag = "node_metrics";
            scrape_interval = 60;
          }
        ];
        outputs = [
          {
            name = "prometheus_exporter";
            amtch = "node_metrics";
            host = "0.0.0.0";
            port = 2021;
          }
        ];
      };
      service.grace = 30;
    };
  };
}
