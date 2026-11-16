# nix-config

Hosted on:

- https://git.byte-sized.fyi/emilia/nix-config
- https://github.com/byte-sized-emi/nix-config
- https://tangled.org/byte-sized-emi.tngl.sh/nix-config (permalink: https://tangled.org/did:plc:ppql4joco7c2yr5csy3mmpux)

## nixnest stability fixes

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
