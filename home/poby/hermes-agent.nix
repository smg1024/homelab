{
  inputs,
  pkgs,
  ...
}: let
  hermesPackages = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};
  hermesAgentExtraPackages = with pkgs; [
    nodejs_22
    python312
  ];
  hermesKrFontEnv = {
    HERMES_KR_FONT = "${pkgs.pretendard}/share/fonts/opentype/Pretendard-Regular.otf";
  };
in {
  home.sessionVariables = hermesKrFontEnv;
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
  systemd.user.sessionVariables = hermesKrFontEnv;

  home.packages = [
    # Use the Nix-built messaging variant so Telegram/Discord/Slack SDKs are
    # available in the sealed Hermes Python environment.
    hermesPackages.messaging
  ] ++ hermesAgentExtraPackages ++ (with pkgs; [
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
