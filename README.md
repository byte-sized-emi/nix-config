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

# nixnest stability fixes

The Soyo M4 Plus (Intel N150) can hard-hang in deep C-states (C8/C10), see
<https://bugs.launchpad.net/bugs/2160711>. Two mitigations are in [modules/hosts/nixnest/configuration.nix](modules/hosts/nixnest/configuration.nix).

To ensure the mitigations are active:

```console
$ cat /sys/module/intel_idle/parameters/max_cstate
2
$ cat /sys/class/watchdog/watchdog0/state
active
$ cat /sys/class/watchdog/watchdog0/timeout
30
# WARNING: Triggers a panic - only do this when downtime is okay!
$ echo c | sudo tee /proc/sysrq-trigger
```
