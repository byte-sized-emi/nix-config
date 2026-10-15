{
  stacks.nw-usage.packages = { pkgs, ... }: {
    nw-usage = pkgs.stdenvNoCC.mkDerivation {
      pname = "nw-usage";
      version = "0.1.0";

      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/neuralwatt/neuralwatt-tools/c4e1018b75c1387ba74f25fcc5cfe95b0ea761c8/scripts/nw-usage";
        sha256 = "399ec86ddb831d0431702df3bddc3349824bb6ed4b54f28783828ce8dc959a21";
      };

      nativeBuildInputs = [ pkgs.makeWrapper ];

      dontUnpack = true;

      installPhase = ''
        install -Dm755 $src $out/bin/nw-usage
        wrapProgram $out/bin/nw-usage \
          --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.curl pkgs.jq ]}
      '';

      meta = with pkgs.lib; {
        homepage = "https://github.com/neuralwatt/neuralwatt-tools";
        description = "CLI for checking Neuralwatt API usage and energy consumption";
        mainProgram = "nw-usage";
        license = licenses.asl20;
      };
    };
  };
}
