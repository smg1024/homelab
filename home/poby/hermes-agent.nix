{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
  ] ++ (with pkgs; [
    tirith
    git
    ripgrep
    fd
    jq
    yq-go
    curl
    wget
    just
  ]);
}
