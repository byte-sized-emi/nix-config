{ pkgs, ... }:
{
  nix.settings = {
    substituters = [ "https://nix-cache.fossi-foundation.org" ];
    trusted-public-keys = [
      "nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs="
    ];
  };

  environment.systemPackages = with pkgs; [
    gnumake
    iverilog
    vscode
    xdot
  ];
}
