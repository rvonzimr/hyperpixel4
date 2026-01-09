{
  description = "NixOS configuration for a Sendspin RPi client";

  inputs = {
    # follow `main` branch of this repository, considered being stable
    sendspin.url = "path:./sendspin-cli";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    nixos-images.url = "github:nvmd/nixos-images/sdimage-installer";
    hyperpixel4.url = "path:./hyperpixel4";
  };

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  outputs =
    {
      self,
      nixpkgs,
      sendspin,
      nixos-raspberrypi,
      nixos-images,
      hyperpixel4,
    }@inputs:
    let
      system = "aarch64-linux";
      # Common modules for both the system and the installer
      userModules = [
        # This brings in the base RPi4 hardware config
        nixos-raspberrypi.nixosModules.raspberry-pi-4.base
        # Add the custom module for the Hyperpixel4 display
        hyperpixel4.nixosModules.default
        # User's custom modules
        sendspin.nixosModules.default
        ./hardware-configuration.nix
        ./configuration.nix
      ];

      # 1. The main system configuration
      sendspin-rpi-system = nixos-raspberrypi.lib.nixosSystem {
        inherit system;
        specialArgs = inputs;
        modules = userModules;
      };

      # 2. The installer configuration
      rpi-installer = nixos-raspberrypi.lib.nixosInstaller {
        inherit system;
        specialArgs = inputs;
        modules = userModules;
      };
    in
    {
      # Expose both configurations for commands like `nixos-rebuild`
      nixosConfigurations = {
        sendspin-rpi = sendspin-rpi-system;
        rpi4-installer = rpi-installer;
      };

      # Expose buildable packages
      packages.${system} = {
        # The installer SD image
        installer = rpi-installer.config.system.build.sdImage;
        # The main system derivation (toplevel) is the default package
        default = sendspin-rpi-system.config.system.build.toplevel;
      };

      devShells.x86_64-linux.default =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          guestfs = pkgs.libguestfs-with-appliance;
        in
        pkgs.mkShell {
          name = "sendspin-rpi-dev-shell";
          packages = with pkgs; [
            qemu
            mtools
          ];
          shellHook = ''
            export LIBGUESTFS_PATH=${guestfs}/lib/guestfs
          '';
        };
    };
}
