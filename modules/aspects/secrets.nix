{inputs, ...}: {
  den.aspects.secrets.nixos = {
    imports = [inputs.sops-nix.nixosModules.sops];
    sops = {
      defaultSopsFile = ../../secrets/ingress.yaml;

      age.sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];
    };
  };
}
