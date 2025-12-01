{ inputs, ... }:
{
  imports = [
    inputs.vicinae.homeManagerModules.default
  ];

  services.vicinae = {
    enable = true;
    autoStart = true;
    settings = {
      rootSearch.searchFiles = false;
      closeOnFocusLoss = true;
      window.opacity = 0.9;
    };
  };
}
