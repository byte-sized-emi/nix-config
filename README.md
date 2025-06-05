# nix-config

The NixOS config for my Soyo M4 minipc, on which I self-host a couple of things.

## Network setup

### home assistant

exposed on port 8123

Whisper running locally on 10300

Piper running locally on 10200

### kanidm

running on localhost:8443

with the cloudflare origin certificate

This is meant to be used either locally through the kanidm CLI, or through cloudflare.
