{...}: {
  home.stateVersion = "25.11";

  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
    PAGER = "less";
    LESS = "-FRX";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyControl = [
      "ignoredups"
      "ignorespace"
    ];
    historyFileSize = 20000;
    historySize = 10000;
  };

  programs.git = {
    enable = true;

    settings = {
      init.defaultBranch = "main";
      pull.ff = "only";
    };
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 50000;
  };
}
