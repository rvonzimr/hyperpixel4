# This is the NixOS module for the Hyperpixel 4 display.
{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.hardware.hyperpixel4;

  # Import the package derivation, passing the correct kernel from the NixOS config
  hyperpixel4-pkg = pkgs.callPackage ./default.nix {
    kernel = config.boot.kernelPackages.kernel;
  };

in
{
  # This creates a new option: hardware.hyperpixel4.enable
  options.hardware.hyperpixel4.enable = mkEnableOption "Hyperpixel 4 display";

  # This is the configuration that will be applied if the option is enabled
  config = mkIf cfg.enable {

    # Add the package's binaries to the system's global path
    environment.systemPackages = [ hyperpixel4-pkg ];

    # Enable the main vc4-kms-v3d graphics driver (a dependency)
    # and the DPI output.
    hardware.raspberry-pi.config = {
      "all" = {
        dt-overlays = {
          "vc4-kms-v3d" = {
            enable = true;
          };
        };
        options = {
          enable_dpi_lcd = {
            enable = true;
            value = 1;
          };
        };
      };
    };

    # Enable and apply the custom device tree overlays from our package
    hardware.deviceTree.enable = true;
    hardware.deviceTree.overlays = map (overlay: {
      name = overlay.name;
      dtboFile = "${hyperpixel4-pkg}/lib/firmware/${overlay.fileName}";
    }) hyperpixel4-pkg.overlays;

    # Define and enable the systemd service for display initialization
    systemd.services.hyperpixel4-init = {
      description = "Hyperpixel 4 Display Init";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${hyperpixel4-pkg}/bin/hyperpixel4-init";
      };
    };
  };
}
