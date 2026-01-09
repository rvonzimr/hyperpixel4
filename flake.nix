{
  description = "NixOS module for Hyperpixel 4 display";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    {
      # This flake's only job is to provide the NixOS module.
      # The module itself will build the package within the correct context.
      nixosModules.default = import ./module.nix;
    };
}
