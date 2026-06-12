{
  mkShell,
  callPackage,
}:
mkShell {
  inputsFrom = [
    (callPackage ./package.nix {})
  ];
}
