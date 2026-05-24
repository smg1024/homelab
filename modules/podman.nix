{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    podman-compose
  ];

  virtualisation.podman = {
    enable = true;

    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  virtualisation.oci-containers.backend = "podman";

  virtualisation.containers.registries.search = [
    "docker.io"
    "ghcr.io"
  ];
}
