{...}: {
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    openFirewall = false;
    allowedHosts = "home.ridewithmin.com";

    settings = {
      title = "Poby Homelab";
      headerStyle = "clean";
    };

    services = [
      {
        "Homelab" = [
          {
            "Yggdrasil" = {
              description = "Ingress node";
              href = "https://home.ridewithmin.com";
            };
          }
          {
            "Midgard" = {
              description = "Application host";
              href = "https://home.ridewithmin.com";
            };
          }
        ];
      }
    ];

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
        };
      }
    ];
  };
}
