{...}: {
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/ata-SSM28128GPTCB3B-S112611_DAAE0797167D10302215";
      content = {
        type = "gpt";

        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";

            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          root = {
            size = "100%";

            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
