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
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            system = system;
            config.allowUnfree = true;
          };
          package = pkgs.callPackage ./package { };
        in
        {
          frpc = package;
          default = package;
        }
      );
      devShells = forAllSystems (system: {
        default = import ./dev {
          pkgs = nixpkgs.legacyPackages.${system};
        };
      });
    };
}
