{
  inputs,
  pkgs,
  ...
}: let
  hermesPackages = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};
in {
  home.packages = [
    # Use the Nix-built messaging variant so Telegram/Discord/Slack SDKs are
    # available in the sealed Hermes Python environment.
    hermesPackages.messaging
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
