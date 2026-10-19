{
  description = "Nix packaging for SakuraFrp frpc";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      # The frpc Docker image only covers these Linux architectures (no MIPS).
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "armv7l-linux"
        "i686-linux"
        "riscv64-linux"
        "loongarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          package = nixpkgs.legacyPackages.${system}.callPackage ./package { };
        in
        {
          natfrp-frpc = package;
          default = package;
        }
      );
    };
}
