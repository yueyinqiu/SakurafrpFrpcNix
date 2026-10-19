{ pkgs, ... }:

pkgs.mkShell {
  packages =
    map
      (
        name:
        import ./packages/${name} {
          pkgs = pkgs;
          name = name;
        }
      )
      (
        builtins.attrNames (
          pkgs.lib.filterAttrs (
            name: type: type == "directory" && builtins.pathExists ./packages/${name}/default.nix
          ) (builtins.readDir ./packages)
        )
      );
}