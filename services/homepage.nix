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

    bookmarks = [
      {
        Personal = [
          {
            GitHub = [
              {
                abbr = "GH";
                href = "https://github.com/smg1024";
              }
            ];
          }
          {
            LinkedIn = [
              {
                abbr = "LI";
                href = "https://www.linkedin.com/in/sangmin-poby";
              }
            ];
          }
        ];
      }
    ];

    services = [
      {
        Applications = [
          {
            "Dev with Min" = {
              description = "Personal developer blog";
              href = "https://blog.ridewithmin.com";
              icon = "mdi-post-outline";
            };
          }
          {
            Forgejo = {
              description = "Git hosting";
              href = "https://git.ridewithmin.com";
              icon = "forgejo.png";
            };
          }
          {
            Vaultwarden = {
              description = "Password manager";
              href = "https://vault.ridewithmin.com";
              icon = "vaultwarden.png";
            };
          }
          {
            "jamye-plz" = {
              description = "Social PWA on alfheim";
              href = "https://jamye-plz.ridewithmin.com";
            };
          }
        ];
      }
      {
        Monitoring = [
          {
            "Uptime Kuma" = {
              description = "Public status page";
              href = "https://status.ridewithmin.com";
              icon = "uptime-kuma.png";
            };
          }
          {
            Beszel = {
              description = "Metrics dashboards (tailnet only)";
              href = "https://beszel.ridewithmin.com";
              icon = "beszel.png";
            };
          }
          {
            VictoriaLogs = {
              description = "Log search (tailnet only)";
              href = "https://logs.ridewithmin.com";
              icon = "victoriametrics.png";
            };
          }
        ];
      }
      {
        Documentation = [
          {
            Docs = {
              description = "Homelab runbooks and architecture";
              href = "https://docs.ridewithmin.com";
              icon = "mdi-book-open-page-variant";
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
