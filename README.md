# nix-config

The NixOS config for my Soyo M4 minipc, on which I self-host a couple of things.

## TODO:
- [ ] setup proper automatic updates of docker images, esp. for the services and the forgejo CI/CD Actions

## Network setup

### home assistant

exposed on port 8123

Whisper running locally on 10300

Piper running locally on 10200

### kanidm

running on localhost:8443

with the cloudflare origin certificate

This is meant to be used either locally through the kanidm CLI, or through cloudflare.

# nix-update-server

## TODOs
- [ ] automatically update nixlaptop
- [ ] how to update nix-update-server with nix-update-server?
- [ ] automatic nix flake updates
- [ ] don't update with local changes in the git repo
- [ ] show notification with cancel button before updating
