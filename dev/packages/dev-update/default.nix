{ name, pkgs, ... }:

pkgs.writeShellApplication {
  name = name;
  text = ''
    xxxxxxxxx
  '';
}