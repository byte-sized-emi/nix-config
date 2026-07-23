# nix-config

## TODO:

- [x] setup proper automatic updates of docker images, esp. for the services and the forgejo CI/CD Actions

# nix-update-server

## TODOs

- [x] automatically update nixlaptop
- [x] how to update nix-update-server with nix-update-server?
- [x] stop server after successful update
- [x] make auto-update fail when the rebuild fails - output a recognisable string on success and failure, and check for it in the ci/cd using the test command
- [x] automatic nix flake updates
- [ ] don't update with local changes in the git repo
- [x] don't show a failed update as success in the CI/CD
- [ ] show notification with cancel button before updating
- [ ] make nix use my cache only when it makes sense
- [x] backup dawarich
