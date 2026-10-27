{inputs, ...}: {
  imports = [inputs.den.flakeModule];

  den.systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];
}
