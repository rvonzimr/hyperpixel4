{
  stdenv,
  dtc,
  python3,
  kernel,
}:
let
in
stdenv.mkDerivation rec {
  pname = "hyperpixel4";
  version = "pi4-dkms";

  src = ./.;

  nativeBuildInputs = [
    dtc
    kernel
  ];

  pythonEnv = python3.withPackages (ps: [
    ps.rpi-gpio
  ]);

  passthru = {
    overlays = [
      {
        name = "vc4-kms-dpi-hyperpixel4";
        fileName = "vc4-kms-dpi-hyperpixel4.dtbo";
      }
    ];
  };

  # The Makefile in this branch is broken and refers to incorrect filenames.
  # We run the dtc commands manually with the correct paths.
  buildPhase = ''
    runHook preBuild

    # Define the full, correct path to the kernel's include directory
    CPP_INCLUDE_PATH="${kernel.dev}/lib/modules/${kernel.version}/source/include"

    cpp -nostdinc -I . -I $CPP_INCLUDE_PATH -undef -x assembler-with-cpp \
      vc4-kms-dpi-hyperpixel4-overlay.dts > preprocessed.dts
    dtc -@ -O dtb -o vc4-kms-dpi-hyperpixel4.dtbo preprocessed.dts

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    # Install overlays compiled in the buildPhase
    mkdir -p $out/lib/firmware/
    cp src/*.dtbo $out/lib/firmware

    # Install binaries from the dist directory in the repo root
    mkdir -p $out/bin
    cp dist/hyperpixel4-init $out/bin/
    cp dist/hyperpixel4-rotate $out/bin/

    # Patch the init script's shebang to use our dedicated python env
    substituteInPlace $out/bin/hyperpixel4-init \
      --replace "/usr/bin/env python" "${pythonEnv}/bin/python"

    runHook postInstall
  '';
}
