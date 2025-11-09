# nix-config

The NixOS config for my Soyo M4 minipc, on which I self-host a couple of things.

## Before using this on nixnest:

- rename "emi" user to "emilia"
- run "kanidmd domain upgrade-check" to check for kanidm upgrade to 1.7

## Network setup

### home assistant

exposed on port 8123

Whisper running locally on 10300

Piper running locally on 10200

### kanidm

running on localhost:8443

with the cloudflare origin certificate

This is meant to be used either locally through the kanidm CLI, or through cloudflare.
