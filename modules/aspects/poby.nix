{den, ...}: {
  den.aspects.poby = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
    ];

    nixos = {
      users.users.poby.openssh.authorizedKeys.keys = [
        # poby workstation
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuQ4STNnixjNDo38AyI0yABKAVfF3hupo66613IgfC7"
        # GitHub Actions CD deploy key (homelab-ci-deploy)
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILdrAuO8z+tW5wGFRY80N1wVUtSuzO4KFvF7YVf2nHxi homelab-ci-deploy"
      ];
      security.sudo.wheelNeedsPassword = false;
    };

    homeManager = {pkgs, ...}: {
      home.stateVersion = "25.11";

      home.sessionVariables = {
        EDITOR = "vim";
        VISUAL = "vim";
        PAGER = "less";
        LESS = "-FRX";
      };

      programs.bash = {
        shellAliases = {
          j = "just";
          jfu = "journalctl -fu";
          ju = "journalctl -u";
          sc = "systemctl";
          scu = "systemctl --user";
          sfailed = "systemctl --failed";
          ts = "tailscale status";
        };

        enable = true;
        enableCompletion = true;
        historyControl = [
          "ignoredups"
          "ignorespace"
        ];
        historyFileSize = 20000;
        historySize = 10000;
      };

      programs.git = {
        enable = true;

        settings = {
          init.defaultBranch = "main";
          pull.ff = "only";
        };
      };

      programs.tmux = {
        enable = true;
        clock24 = true;
        historyLimit = 50000;
      };

      home.packages = with pkgs; [
        age
        just
        sops
      ];
    };
  };
}
