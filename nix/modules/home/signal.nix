{
  xdg.desktopEntries.signal = {
    name = "Signal";
    exec = "signal-desktop --password-store=\"kwallet6\" --use-tray-icon %U";
    comment = "Private messaging from your desktop";
    categories = [
      "Network"
      "InstantMessaging"
      "Chat"
    ];
    icon = "signal-desktop";
    mimeType = [
      "x-scheme-handler/signalcaptcha"
      "x-scheme-handler/sgnl"
    ];
  };
}
