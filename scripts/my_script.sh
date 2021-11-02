#!/bin/bash


bash ./create_initrd.sh "/home/alex/work/beaglev/binary/jammy.rootfs" "/home/alex/work/beaglev/riscv-linux/build_starlight_ubuntu" "/mnt/jammy.rootfs" "5.13.0-1004-generic" "5.15.0-rc7-starlight+"

read -p "rootfs is up-to-date, waiting for rootfs with updated initrd from VM..."

bash ./create_disk_image.sh "ubuntu_beaglev.img" "/home/alex/work/beaglev/binary/jammy_final.rootfs" "/home/alex/work/beaglev/binary/jammy.cidata" "/home/alex/work/beaglev/u-boot/u-boot.itb"
