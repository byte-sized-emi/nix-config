{
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="057e", ATTR{idProduct}=="2009", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="0003", MODE="0666"
  '';
}
