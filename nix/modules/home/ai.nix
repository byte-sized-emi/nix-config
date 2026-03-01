{
  programs.opencode = {
    enable = true;
    settings = {
      permission = {
        edit = "allow";
        bash = "ask";
        webfetch = "allow";
        doom_loop = "ask";
        external_directory = "ask";
      };
    };
  };
}
