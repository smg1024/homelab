{
  config,
  inputs,
  ...
}: {
  imports = [inputs.jamye-plz.nixosModules.default];

  sops.secrets."jamye-plz/jwt_secret" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/kakao_client_id" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/kakao_client_secret" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/google_client_id" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/google_client_secret" = {sopsFile = ../secrets/jamye-plz.yaml;};

  sops.templates."jamye-plz.env" = {
    owner = "jamye";
    restartUnits = ["jamye-plz-backend.service"];
    content = ''
      JWT_SECRET=${config.sops.placeholder."jamye-plz/jwt_secret"}
      KAKAO_CLIENT_ID=${config.sops.placeholder."jamye-plz/kakao_client_id"}
      KAKAO_CLIENT_SECRET=${config.sops.placeholder."jamye-plz/kakao_client_secret"}
      GOOGLE_CLIENT_ID=${config.sops.placeholder."jamye-plz/google_client_id"}
      GOOGLE_CLIENT_SECRET=${config.sops.placeholder."jamye-plz/google_client_secret"}
      KAKAO_REDIRECT_URI=https://jamye-plz.ridewithmin.com/api/auth/kakao/callback
      GOOGLE_REDIRECT_URI=https://jamye-plz.ridewithmin.com/api/auth/google/callback
      FRONTEND_ORIGIN=https://jamye-plz.ridewithmin.com
    '';
  };

  services.jamye-plz = {
    enable = true;
    listenPort = 8080;
    environmentFile = config.sops.templates."jamye-plz.env".path;
  };
}
