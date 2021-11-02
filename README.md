# Build

1. Build JH7100_ddrinit: alex/int/alex/spl

Download an elf toolchain from SiFive

	$ cd build
	$ PATH=$TOOLCHAIN_PATH/bin/:$PATH make

To flash this new firmware, at the BeagleV boot, press "[ECHAP]", enter "root@s5t" and select "update ddr init firmware", use minicom xsend functionality to send the file.

2. Build OpenSBI: origin/master

	$ make PLATFORM=generic CROSS_COMPILE=riscv64-linux-gnu-

3. Build u-boot SPL and u-boot: alex/int/alex/spl_support

	$ make starfive_jh7100_starlight_smode_defconfig
	$ OPENSBI=/home/alex/work/opensbi/build/platform/generic/firmware/fw_dynamic.bin make -j8 CROSS_COMPILE=riscv64-linux-gnu-

  * u-boot SPL binary must be preceded by its size on 4B, as per Buildroot board/beaglev/post-build.sh:

	$ perl -e 'print pack("l", (stat @ARGV[0])[7])' /home/alex/work/beaglev/u-boot/spl/u-boot-spl-dtb.bin > /home/alex/work/beaglev/u-boot/spl/u-boot-spl-dtb.bin.out
	$ cat /home/alex/work/beaglev/u-boot/spl/u-boot-spl-dtb.bin >> /home/alex/work/beaglev/u-boot/spl/u-boot-spl-dtb.bin.out

To flash u-boot SPL, at the BeagleV boot, press "[ECHAP]", select "update u-boot", use minicom xsend functionality to send the file.
You will never have to update those firmwares now :)

4. Build Linux: alex/int/alex/beaglev

	$ make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- CC="ccache riscv64-linux-gnu-gcc" -j8 starlight_ubuntu_defconfig O=build_starlight_ubuntu
	$ cd build_starlight_ubuntu
	$ make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- CC="ccache riscv64-linux-gnu-gcc" -j8

5. Extract rootfs/CIDATA from unmatched jammy image: https://cdimage.ubuntu.com/ubuntu-server/daily-preinstalled/pending/jammy-preinstalled-server-riscv64+unmatched.img.xz

	$ sudo kpartx -a -v jammy-preinstalled-server-riscv64+unmatched.img
	$ sudo dd if=/dev/mapper/loopXXp1 of=jammy.rootfs
	$ sudo dd if=/dev/mapper/loopXXp12 of=jammy.cidata

TODO there must more natural way of doing this.

6. Update rootfs with new Linux Kernel, create initrd for it and create the sdcard image

	a. First we need to update the rootfs, launch scripts/my_script.sh that contains your path:

		$ bash my_script.sh

	This will update in-place the rootfs and wait for the initrd to be created from the VM.

	b. Create the initrd from a VM (otherwise it fails totally from a qemu user emulated chroot...)

	Send the updated rootfs to a VM and then launch from the VM:

		$ sudo mount $rootfs /mnt
		$ sudo mount -o bind /proc /mnt/proc
		$ sudo mount -o bind /sys /mnt/sys
		$ sudo mount -o bind /dev /mnt/dev
		$ sudo chroot /mnt update-initramfs -c -k "5.15.0-rc7-starlight+"
		$ sudo chroot /mnt u-boot-update
		$ sudo umount /mnt/proc
		$ sudo umount /mnt/sys
		$ sudo umount /mnt/dev
		$ sudo umount /mnt

	c. Retrieve the updated rootfs on the host at the same location and press a key, this will create the sdcard image.

7. Flash the sdcard image on a sdcard

	$ sudo dd if=$sdcardimage of=/dev/mmcblk0

Notes
=====

#. SDCard layout

part1 : sector 	=> Linux => GUID "Linux filesystem" must be a "legacy BIOS bootable" partition (IMO to match 'bootable' attribute in uboot env)
part12: sector [219136; 227327] => CIDATA 4M (copy from unmatched for now) => GUID "Linux filesystem"
part14: sector [2048; 10239] 8192 sectors => u-boot + openSBI itb => TODO which GUID to choose? ef02 "BIOS boot partition
part15: sector [10240; 219135] 217088 sectors => UEFI GUID=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
=> sudo mkfs.vfat -F 32 -n UEFI /dev/sda15 # MUST be done with unmatched rootfs (look at /etc/fstab)
