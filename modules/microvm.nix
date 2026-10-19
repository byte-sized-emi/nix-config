{
  inputs,
  __findFile,
  ...
}:
{
  den.aspects.pi-vm = {
    includes = [ <ssh-server> ];

    nixos =
      { lib, ... }:
      {
        imports = [ inputs.microvm.nixosModules.microvm ];

        # home-manager.users.emilia = {
        #   imports = [ inputs.sops-nix.homeManagerModules.sops ];
        #   sops = {
        #     defaultSopsFile = ../secrets.yaml;
        #     age.keyFile = "/var/lib/sops-nix/key.txt";
        #   };
        # };

        microvm = {
          hypervisor = "cloud-hypervisor";
          vcpu = 4;
          mem = 2048;
          balloon = true;
          hotplugMem = 6144;
          hotpluggedMem = 0;
          socket = "control.socket";

          shares = [
            {
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
              proto = "virtiofs";
            }
            {
              tag = "sops-age";
              source = "/run/secrets/sops-age/pi-microvm";
              mountPoint = "/run/secrets/sops-age/pi-microvm";
              proto = "virtiofs";
              readOnly = true;
            }
          ];

          writableStoreOverlay = "/nix/.rw-store";
          volumes = [
            {
              image = "store-overlay.img";
              mountPoint = "/nix/.rw-store";
              size = 8192;
            }
          ];

          interfaces = [
            {
              type = "macvtap";
              id = "vm-pi";
              mac = "02:00:00:00:0a:01";
              macvtap = {
                link = "enp2s0";
                mode = "bridge";
              };
            }
          ];

          vsock = {
            cid = 100;
            ssh.enable = true;
          };
        };

        boot.loader.systemd-boot.enable = lib.mkForce false;
        boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

        nix.settings.auto-optimise-store = lib.mkForce false;
        nix.optimise.automatic = lib.mkForce false;

        boot.kernelModules = [ "virtio_mem" ];
        boot.kernelParams = [ "memory_hotplug.online_policy=online" ];

        system.stateVersion = "26.11";
      };
  };

  den.aspects.microvm-host.nixos = { pkgs, ... }: {
    imports = [ inputs.microvm.nixosModules.host ];

    sops.secrets."pi-microvm/neuralwatt-key" = {
      key = "pi/neuralwatt";
      owner = "emilia";
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "pi-vm" ''
        set -euo pipefail
        name=pi-vm
        systemctl stop "microvm@$name.service" 2>/dev/null || true
        rm -rf "/var/lib/microvms/$name"
        microvm -f ${../.} -c "$name"
        systemctl start "microvm@$name.service"
        exec microvm -s "$name" -- -l emilia
      '')
    ];
  };
}
