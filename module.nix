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

  # Import the package derivation from the separate default.nix file
  hyperpixel4-pkg = pkgs.callPackage ./default.nix { };

in
{
  # This creates a new option: hardware.hyperpixel4.enable
  options.hardware.hyperpixel4.enable = mkEnableOption "Hyperpixel 4 display";

  # This is the configuration that will be applied if the option is enabled
  config = mkIf cfg.enable {

    # Add the package's binaries to the system's global path
    environment.systemPackages = [ hyperpixel4-pkg ];

    # Add the non-overlay boot configuration settings
    hardware.raspberry-pi.config = {
      "all" = {
        options = {
          enable_dpi_lcd = {
            enable = true;
            value = 1;
          };
          dpi_group = {
            enable = true;
            value = 2;
          };
          dpi_mode = {
            enable = true;
            value = 87;
          };
          dpi_output_format = {
            enable = true;
            value = "0x7f216";
          };
          dpi_timings = {
            enable = true;
            value = "480 0 10 16 59 800 0 15 113 15 0 0 0 60 0 32000000 6";
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
