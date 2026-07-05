{...}: {
  services.victorialogs = {
    enable = true;
    listenAddress = ":9428";
    extraOptions = [
      "-retentionPeriod=14d"
    ];
  };
}
