{pkgs, ...}: {
  imports = [
    ./hermes-agent.nix
  ];

  home.packages = with pkgs; [
    sqlite
  ];

  programs.bash.shellAliases = {
    logs-forgejo = "journalctl -fu forgejo";
    logs-homepage = "journalctl -fu homepage-dashboard";
    logs-vaultwarden = "journalctl -fu vaultwarden";
    pods = "podman ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'";
  };
}
