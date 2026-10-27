{
  den,
  inputs,
  ...
}: {
  den.aspects.homelab-base = {
    includes = [
      den.batteries.hostname
      den.aspects.base
      den.aspects.gc
      den.aspects.swap
      den.aspects.ssh
      den.aspects.tailscale
      den.aspects.secrets
      den.aspects.log-shipper
      den.aspects.beszel-agent
    ];

    nixos = {
      imports = [inputs.disko.nixosModules.disko];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    };
  };
}
