{
  services.fluent-bit = {
    enable = true;
    settings = {
      pipeline = {
        inputs = [
          {
            name = "node_exporter_metrics";
            tag = "node_metrics";
            scrape_interval = 60;
          }
        ];
        outputs = [
          {
            name = "prometheus_exporter";
            match = "node_metrics";
            host = "0.0.0.0";
            port = 2021;
          }
        ];
      };
      service.grace = 30;
    };
  };
}
