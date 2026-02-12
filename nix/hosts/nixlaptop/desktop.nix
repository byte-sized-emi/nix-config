{ pkgs, ... }:
{
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  programs.niri.enable = true;

  services.gnome.gnome-keyring.enable = false;
  security.pam.services.login.kwallet.enable = true;

  xdg.portal.extraPortals = [
    pkgs.kdePackages.kwallet
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };
}
