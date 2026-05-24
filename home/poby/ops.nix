{pkgs, ...}: {
  home.packages = with pkgs; [
    age
    just
    sops
  ];

  programs.bash.shellAliases = {
    j = "just";
    jfu = "journalctl -fu";
    ju = "journalctl -u";
    sc = "systemctl";
    scu = "systemctl --user";
    sfailed = "systemctl --failed";
    ts = "tailscale status";
  };
}
