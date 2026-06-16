{ ... }:

{
  users.users.poby = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];

    openssh.authorizedKeys.keys = [
      # poby workstation
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuQ4STNnixjNDo38AyI0yABKAVfF3hupo66613IgfC7"
      # GitHub Actions CD deploy key (homelab-ci-deploy)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILdrAuO8z+tW5wGFRY80N1wVUtSuzO4KFvF7YVf2nHxi homelab-ci-deploy"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
