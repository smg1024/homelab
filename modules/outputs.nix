{self, ...}: {
  perSystem = {pkgs, ...}: {
    packages.docs = pkgs.callPackage ../docs/package.nix {};
    devShells.docs = pkgs.callPackage ../docs/shell.nix {};
    checks.jamye-host-swap-restore = import ../tests/jamye-host-swap.nix {inherit pkgs;};
    checks.minio-compat = import ../tests/minio-compat.nix {
      inherit pkgs;
      hosts = self.nixosConfigurations;
    };
    formatter = pkgs.alejandra;
  };
}
