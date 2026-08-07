{ __findFile, ... }:
{
  apps.steam = {
    includes = [
      (<den/unfree> [
        "steam"
        "steam-unwrapped"
      ])
    ];
    nixos = {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };
    };
    homeManager = {
      xdg.desktopEntries.steam = {
        name = "Steam";
        exec = "steam -system-composer %U";
        icon = "steam";
        mimeType = [
          "x-scheme-handler/steam"
          "x-scheme-handler/steamlink"
        ];
      };
    };
  };
}
