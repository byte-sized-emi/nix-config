{
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 7;
    efi.canTouchEfiVariables = true;
  };
}
