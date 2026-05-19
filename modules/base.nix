{ pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.trusted-users = [
    "root"
    "@wheel"
  ];

  time.timeZone = "Asia/Seoul";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    tmux
    jq
    fd
    ripgrep
    lsof
    pciutils
    usbutils
    dnsutils
  ];
}
