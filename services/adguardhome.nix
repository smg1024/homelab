{...}: let
  lanInterface = "enp2s0";
  lanSubnet = "192.168.0.0/24";
  dnsAddress = "192.168.0.53";
in {
  services.adguardhome = {
    enable = true;

    # Keep the first-run wizard so the administrator password is created
    # outside the Nix store. Later settings persist in /var/lib/AdGuardHome.
    settings = null;
    openFirewall = false;
  };

  # Match both the private source subnet and the reserved destination. If the
  # DHCP reservation drifts, DNS fails closed instead of becoming reachable on
  # another address or through an accidental router port-forward.
  networking.firewall.extraCommands = ''
    iptables -w -A nixos-fw -i ${lanInterface} -s ${lanSubnet} -d ${dnsAddress} -p tcp --dport 53 -j nixos-fw-accept
    iptables -w -A nixos-fw -i ${lanInterface} -s ${lanSubnet} -d ${dnsAddress} -p udp --dport 53 -j nixos-fw-accept
  '';
}
