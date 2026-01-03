{
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  programs.niri.enable = true;

  services.gnome.gnome-keyring.enable = false;
  security.pam.services.login.kwallet.enable = true;
  security.pam.services.login.kwallet.forceRun = true;
  # security.pam.services.emilia.kwallet.enable = true;
  # security.pam.services.emilia.kwallet.forceRun = true;
  # security.pam.services.niri.kwallet.enable = true;
  # security.pam.services.niri.kwallet.forceRun = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };
}
