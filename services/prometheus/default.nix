{...}: {
  services.prometheus = {
    enable = true;
    enableReload = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "15d";

    ruleFiles = [
      ./node-health-alert-rule.yml
    ];

    scrapeConfigs = [
      {
        job_name = "nodes";
        scrape_interval = "3m";

        static_configs = [
          {
            targets = [
              "127.0.0.1:9100"
              "midgard.tail6fc192.ts.net:9100"
            ];
          }
        ];
      }
    ];
  };
}
