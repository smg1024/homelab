{den, ...}: {
  den.hosts.x86_64-linux.midgard.users.poby.classes = ["homeManager"];

  den.aspects.midgard = {
    includes = [
      den.aspects.homelab-base
      den.aspects.podman
      den.aspects.homepage
      den.aspects.forgejo
      den.aspects.vaultwarden
    ];

    nixos = {pkgs, ...}: {
      imports = [
        ./_midgard/hardware-configuration.nix
        ./_midgard/disko.nix
      ];

      services.dbus.implementation = "dbus";

      fonts = {
        packages = with pkgs; [
          pretendard
          noto-fonts-cjk-sans
        ];

        fontconfig = {
          enable = true;
          defaultFonts.sansSerif = [
            "Pretendard"
            "Noto Sans CJK KR"
          ];
        };
      };

      services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
      };

      system.stateVersion = "25.11";
    };

    provides.poby = {
      includes = [den.aspects.hermes-agent];
      homeManager = {pkgs, ...}: {
        home.packages = with pkgs; [
          sqlite
        ];

        programs.bash.shellAliases = {
          logs-forgejo = "journalctl -fu forgejo";
          logs-homepage = "journalctl -fu homepage-dashboard";
          logs-vaultwarden = "journalctl -fu vaultwarden";
          pods = "podman ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'";
        };
      };
    };
  };
}
