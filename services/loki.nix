{config, ...}: let
  dataDir = config.services.loki.dataDir;
in {
  services.loki = {
    enable = true;

    configuration = {
      auth_enabled = false;

      server = {
        http_listen_address = "0.0.0.0";
        http_listen_port = 3100;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = 9096;
      };

      common = {
        instance_addr = "127.0.0.1";
        path_prefix = dataDir;
        replication_factor = 1;

        ring = {
          kvstore.store = "inmemory";
        };

        storage = {
          filesystem = {
            chunks_directory = "${dataDir}/chunks";
            rules_directory = "${dataDir}/rules";
          };
        };
      };

      schema_config = {
        configs = [
          {
            from = "2024-04-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";

            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };

      compactor = {
        working_directory = "${dataDir}/compactor";
        compaction_interval = "10m";
        retention_enabled = true;
        retention_delete_delay = "2h";
        delete_request_store = "filesystem";
      };

      limits_config = {
        retention_period = "14d";
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        ingestion_rate_mb = 4;
        ingestion_burst_size_mb = 8;
      };
    };
  };
}
