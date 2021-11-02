#!/bin/bash

rootfs_path="$1"
linux_build_path="$2"
tmp_mount_path="$3"
old_kernel_str_version="$4"
new_kernel_str_version="$5"

create_initrd()
{
    rootfs="$1"
    mount_dir="$2"
    kernel_build_dir="$3"
    kernel_version="$4"
    old_kernel_version="$5"

    mkdir -p $mount_dir
    mount $rootfs $mount_dir

    # Clear previous kernel
    rm -rf $mount_dir/boot/config-$old_kernel_version
    rm -rf $mount_dir/boot/initrd.img-$old_kernel_version
    rm -rf $mount_dir/boot/vmlinuz-$old_kernel_version
    rm -rf $mount_dir/boot/System.map-$old_kernel_version
    rm -rf $mount_dir/lib/modules/$old_kernel_version
    rm -rf $mount_dir/lib/firmware/$old_kernel_version

    # Copy new one
    rsync -av $kernel_build_dir/debian/linux-image/boot/ $mount_dir/boot/
    # strip the modules!
    find $kernel_build_dir/debian/linux-image/lib/modules/$kernel_version -name *.ko -exec riscv64-linux-gnu-strip --strip-unneeded {} +
    rsync -av $kernel_build_dir/debian/linux-image/lib/modules/$kernel_version $mount_dir/lib/modules/
    mkdir -p $mount_dir/lib/firmware/$kernel_version/device-tree/
    # TODO that's dirty, it copies all temp files
    rsync -av $kernel_build_dir/arch/riscv/boot/dts/ $mount_dir/lib/firmware/$kernel_version/device-tree/

    #mount -o bind /proc $mount_dir/proc
    #mount -o bind /sys  $mount_dir/sys
    #mount -o bind /dev  $mount_dir/dev
    #chroot $mount_dir /bin/bash -c "update-initramfs -c -t -k \"$kernel_version\""
    #chroot $mount_dir u-boot-update # to update extlinux.conf
    #umount $mount_dir/proc
    #umount $mount_dir/sys
    #umount $mount_dir/dev
    umount $rootfs
}

create_initrd $rootfs_path $tmp_mount_path $linux_build_path $new_kernel_str_version $old_kernel_str_version
