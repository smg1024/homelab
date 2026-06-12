{
  stdenvNoCC,
  zensical,
}:
stdenvNoCC.mkDerivation {
  name = "homelab-docs";
  src = ./.;

  nativeBuildInputs = [
    zensical
  ];
}
