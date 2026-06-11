{
  config,
  lib,
  ...
}: {
  sops.secrets."grafana/admin_password" = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
    restartUnits = [
      "grafana.service"
    ];
  };

  sops.secrets."grafana/secret_key" = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
    restartUnits = [
      "grafana.service"
    ];
  };

  sops.secrets."grafana/renderer_token" = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
    restartUnits = [
      "grafana.service"
    ];
  };

  sops.secrets."grafana/renderer_env" = {
    mode = "0400";
    restartUnits = [
      "grafana-image-renderer.service"
    ];
  };

  services.grafana = {
    enable = true;
    openFirewall = false;

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3003;
        domain = "grafana.ridewithmin.com";
        root_url = "https://grafana.ridewithmin.com/";
      };

      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };

      rendering = {
        concurrent_render_request_limit = 2;
        renderer_token = "$__file{${config.sops.secrets."grafana/renderer_token".path}}";
      };

      "auth.anonymous".enabled = false;
      security = {
        admin_password = "$__file{${config.sops.secrets."grafana/admin_password".path}}";
        secret_key = "$__file{${config.sops.secrets."grafana/secret_key".path}}";
        cookie_secure = true;
      };
      users.allow_sign_up = false;
    };

    provision = {
      datasources.settings = {
        apiVersion = 1;

        datasources = [
          {
            name = "Prometheus";
            uid = "prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
            isDefault = true;
            editable = false;
            jsonData = {
              timeInterval = "3m";
            };
          }
          {
            name = "Loki";
            uid = "loki";
            type = "loki";
            access = "proxy";
            url = "http://127.0.0.1:3100";
            editable = false;
            jsonData = {
              maxLines = 1000;
            };
          }
        ];
      };

      dashboards.settings = {
        apiVersion = 1;

        providers = [
          {
            name = "Homelab";
            orgId = 1;
            folder = "Homelab";
            type = "file";
            disableDeletion = true;
            allowUiUpdates = true;
            updateIntervalSeconds = 60;
            options.path = ./dashboards;
          }
        ];
      };
    };
  };

  services.grafana-image-renderer = {
    enable = true;
    provisionGrafana = true;

    settings = {
      server.addr = "127.0.0.1:8081";
    };
  };

  systemd.services.grafana-image-renderer.serviceConfig.EnvironmentFile =
    config.sops.secrets."grafana/renderer_env".path;

  systemd.services.grafana.preStart = lib.mkAfter ''
    if [ -s ${config.sops.secrets."grafana/admin_password".path} ]; then
      tr -d '\r\n' < ${config.sops.secrets."grafana/admin_password".path} \
        | ${config.services.grafana.package}/bin/grafana cli \
          --homepath ${config.services.grafana.dataDir} \
          admin reset-admin-password \
          --password-from-stdin \
        || true
    fi
  '';
}
