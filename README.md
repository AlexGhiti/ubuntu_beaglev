# Ubuntu install

First, we will flash the necessary firmwares in the SPI flash: `ddrinit` and `u-boot SPL`. Those two firmwares likely won't require any updates as their only job is to pass control to `u-boot/openSBI` that are resident on the sdcard and that will certainly require fixes and updates. In the Ubuntu image, we decided to have them on the sdcard so that they can be updated automatically when upgrading the `u-boot-starfive` package, so that you won't ever have to to plug your FTDI in.

To update the SPI flash firmwares, prepare the FTDI following the instructions from [1] section "Preparing the board".

[1] https://bootlin.com/blog/buildroot-beagle-v/

1. Install `JH7100_ddrinit` firmware:

You can either download a pre-built version https://github.com/AlexGhiti/JH7100_ddrinit/releases/tag/ubuntu_beaglev or build it using the following instructions:

Build
-----

Download an elf toolchain from SiFive: https://github.com/sifive/freedom-tools/releases


	$ cd build
	$ PATH=$TOOLCHAIN_PATH/bin/:$PATH make


Flash
-----

To flash this new firmware, at the BeagleV boot, press any key before the 2 seconds countdown end.
The following menu will appear:


	***************************************************
	*************** FLASH PROGRAMMING *****************
	***************************************************

	0:update uboot
	1:quit
	select the function:


enter "root@s5t" and the following menu will appear:


	0:update second boot
	1:update ddr init boot
	2:update uboot
	3:quit
	select the function:


Select "update ddr init firmware" and use minicom xsend functionality to send the file named "ddrinit-2133-XXXXXX.bin.out" which is in the `build` directory.


2. u-boot SPL flash

Reboot the board and enter the flash programming menu:


	***************************************************
	*************** FLASH PROGRAMMING *****************
	***************************************************

	0:update uboot
	1:quit
	select the function:


Select "update uboot" and use minicom xsend functionality to send the file named "".


3. Flash the Ubuntu image on the sdcard

Download the Ubuntu image from [1] and flash it on your sdcard using:


	$ dd if=XXX.img of=/dev/YOUR_SDCARD_BLOCK_DEVICE


Insert the sdcard and then enjoy using Ubuntu on the BeagleV :)
