{...}: {
  programs.bash.shellAliases = {
    logs-caddy = "journalctl -fu caddy";
    logs-cloudflared = "journalctl -fu cloudflared-tunnel-7464b4c7-93aa-4ef0-990d-76d6b0bb158a";
    logs-kuma = "journalctl -fu uptime-kuma";
    status-ingress = "systemctl status caddy cloudflared-tunnel-7464b4c7-93aa-4ef0-990d-76d6b0bb158a uptime-kuma";
  };
}
