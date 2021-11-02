Build
-----

1. Build OpenSBI: origin/master

$ make PLATFORM=generic CROSS_COMPILE=riscv64-linux-gnu-

2. Build u-boot SPL and u-boot: alex/int/alex/spl_support

$ make starfive_jh7100_starlight_smode_defconfig
$ OPENSBI=/home/alex/work/opensbi/build/platform/generic/firmware/fw_dynamic.bin make -j8

  * u-boot SPL binary must be preceded by its size on 4B, as per Buildroot board/beaglev/post-build.sh:

$ perl -e 'print pack("l", (stat @ARGV[0])[7])' /home/alex/work/beaglev/u-boot/spl/u-boot-spl-dtb.bin > /home/alex/work/beaglev/u-boot/spl/u-boot-spl-dtb.bin.out
$ cat /home/alex/work/beaglev/u-boot/spl/u-boot-spl-dtb.bin >> /home/alex/work/beaglev/u-boot/spl/u-boot-spl-dtb.bin.out

3. Build Linux: alex/int/alex/beaglev

$ make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- CC="ccache riscv64-linux-gnu-gcc" -j8 starlight_ubuntu_defconfig O=build_starlight_ubuntu
$ cd build_starlight_ubuntu
$ make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- CC="ccache riscv64-linux-gnu-gcc" -j8

4. Extract rootfs/CIDATA from unmatched jammy image: https://cdimage.ubuntu.com/ubuntu-server/daily-preinstalled/pending/jammy-preinstalled-server-riscv64+unmatched.img.xz

$ sudo kpartx -a -v jammy-preinstalled-server-riscv64+unmatched.img.xz
$ sudo dd if=/dev/mapper/loopXXp1 of=jammy.rootfs
$ sudo dd if=/dev/mapper/loopXXp12 of=jammy.cidata

TODO there must more natural way of doing this.

5. Create sdcard image

$ sudo bash create_disk_image.sh sdcard.img jammy.rootfs

6. Create initrd from a VM...otherwise it fails totally from a qemu user emulated chroot...

Send jammy.rootfs modified by create_disk_image.sh to a VM and then launch from the VM:

$ sudo mount jammy.rootfs /mnt
$ sudo chroot /mnt update-initramfs -c -k "5.15.0-rc7-starlight+"

7. Update extlinux.conf with new kernel

8. Retrieve this rootfs and write it to the sdcard.img



5. SDCard layout

part1 : sector 	=> Linux => GUID "Linux filesystem" must be a "legacy BIOS bootable" partition (IMO to match 'bootable' attribute in uboot env)
part12: sector [219136; 227327] => CIDATA 4M (copy from unmatched for now) => GUID "Linux filesystem"
part14: sector [2048; 10239] 8192 sectors => u-boot + openSBI itb => TODO which GUID to choose? ef02 "BIOS boot partition
part15: sector [10240; 219135] 217088 sectors => UEFI GUID=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
=> sudo mkfs.vfat -F 32 -n UEFI /dev/sda15 # MUST be done with unmatched rootfs (look at /etc/fstab)



ERRORS:
[   38.880663] cloud-init[581]: OSError: [Errno 30] Read-only file system: '/var/lib/cloud/data'
[   34.056610] cloud-init[569]: OSError: [Errno 30] Read-only file system: '/var/crash/_usr_bin_cloud-init.0.crash'
[   27.453099] blk_update_request: I/O error, dev mmcblk0, sector 10240 op 0x1:(WRITE) flags 0x800 phys_seg 1 prio c0
[   27.463958] Buffer I/O error on dev mmcblk0p15, logical block 0, lost sync page write
[   20.250690] blk_update_request: I/O error, dev mmcblk0, sector 227328 op 0x1:(WRITE) flags 0x800 phys_seg 1 prio 0
[   20.261594] Buffer I/O error on dev mmcblk0p1, logical block 0, lost sync page write
[   20.269407] EXT4-fs (mmcblk0p1): I/O error while writing superblock


=> Then fails to login...
