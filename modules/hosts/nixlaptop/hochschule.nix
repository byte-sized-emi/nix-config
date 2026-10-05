{
  den.aspects.nixlaptop.nixos = { pkgs, ... }: {
    # https://wiki.nixos.org/wiki/QEMU
    environment.systemPackages = with pkgs; [
      qemu
      # scilab-bin
    ];

    systemd.tmpfiles.rules = [ "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware" ];

    boot.binfmt.emulatedSystems = [
      "aarch64-linux"
      "riscv64-linux"
    ];
  };
}
