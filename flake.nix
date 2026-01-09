{
  description = "NixOS module and package for Hyperpixel 4 display";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      # The package's output is arch-independent.
      supportedSystems = [ "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # Expose the NixOS module from module.nix
      nixosModules.default = import ./module.nix;

      # Expose the package from default.nix
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.callPackage ./default.nix { };
        }
      );
    };
}
