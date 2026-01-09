build:
	dtc -@ -I dts -O dtb -o vc4-kms-dpi-hyperpixel4.dtbo vc4-kms-dpi-hyperpixel4-overlay.dts

install:
	cp hyperpixel4.dtbo /boot/overlays/

test:
	dtoverlay hyperpixel4.dtbo
