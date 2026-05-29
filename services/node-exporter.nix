{...}: {
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    listenAddress = "0.0.0.0";
    openFirewall = false;

    enabledCollectors = [
      "systemd"
    ];

    extraFlags = [
      "--collector.systemd.unit-include=.+\\.service"
    ];
  };
}
