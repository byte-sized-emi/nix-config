{ pkgs, ... }:
let
  allowAccess =
    id:
    let
      subIds = pkgs.lib.strings.splitString ":" id;
      idVendor = builtins.elemAt subIds 0;
      idProduct = builtins.elemAt subIds 1;
    in
    ''SUBSYSTEM=="usb", ATTR{idVendor}=="${idVendor}", ATTR{idProduct}=="${idProduct}", MODE="0666"'';
in
{
  services.udev.extraRules = pkgs.lib.strings.concatLines (
    builtins.map allowAccess [
      "057e:2009"
      "2e8a:0003"
      "057e:0337"
    ]
  );
}
