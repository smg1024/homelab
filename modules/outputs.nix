{self, ...}: {
  perSystem = {pkgs, ...}: {
    packages.docs = pkgs.callPackage ../docs/package.nix {};
    devShells.docs = pkgs.callPackage ../docs/shell.nix {};
    checks.minio-compat = import ../tests/minio-compat.nix {
      inherit pkgs;
      hosts = self.nixosConfigurations;
    };
    formatter = pkgs.alejandra;
  };
}
