{...}: {
  services.forgejo = {
    enable = true;

    settings = {
      DEFAULT = {
        APP_NAME = "Git with Min!";
      };

      server = {
        DOMAIN = "git.ridewithmin.com";
        ROOT_URL = "https://git.ridewithmin.com/";
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3000;
        DISABLE_SSH = true;
      };

      service = {
        DISABLE_REGISTRATION = true;
      };

      session = {
        COOKIE_SECURE = true;
      };
    };
  };
}
