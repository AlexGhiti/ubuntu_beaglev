#!/bin/bash

image_name="$1"
image_size=4290755584  # 4289690112 #3752819200 #3758096384

rootfs_path="$2"

create_empty_disk_image() {
    # Prepare an empty disk image
    dd if=/dev/zero of="$1" bs=1 count=0 seek="${image_size}"
}

mount_image() {
    backing_img="$1"
    local rootpart="$2"
    kpartx_mapping="$(kpartx -s -v -a ${backing_img})"

    # Find the loop device
    loop_p1="$(echo -e ${kpartx_mapping} | head -n1 | awk '{print$3}')"
    loop_device="/dev/${loop_p1%p[0-9]*}"
    if [ ! -b ${loop_device} ]; then
        echo "unable to find loop device for ${backing_img}"
        exit 1
    fi

    # Find the rootfs location
    rootfs_dev_mapper="/dev/mapper/${loop_p1%%[0-9]}${rootpart}"
    if [ ! -b "${rootfs_dev_mapper}" ]; then
        echo "${rootfs_dev_mapper} is not a block device";
        exit 1
    fi

    # Add some information to the debug logs
    echo "Mounted disk image ${backing_img} to ${rootfs_dev_mapper}"
    blkid ${rootfs_dev_mapper}

    return 0
}

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

    mount -o bind /proc $mount_dir/proc
    mount -o bind /sys  $mount_dir/sys
    mount -o bind /dev  $mount_dir/dev
    #chroot $mount_dir /bin/bash -c "update-initramfs -c -t -k \"$kernel_version\""
    #chroot $mount_dir u-boot-update # to update extlinux.conf
    umount $mount_dir/proc
    umount $mount_dir/sys
    umount $mount_dir/dev
    sync
    umount $rootfs
}

disk_image="$image_name"

rm -f "$disk_image"
create_empty_disk_image "$disk_image"
#sgdisk --zap-all "$disk_image"

rootfs_part="1"
cidata_part="12"
u_boot_part="14"
uefi_part="15"

sgdisk "${disk_image}"\
    --set-alignment=2\
    --new=$u_boot_part:2048:10239\
    --change-name=$u_boot_part:loader2\
    --typecode=$u_boot_part:ef02\
    --new=$uefi_part:10240:219135\
    --typecode=$uefi_part:ef00\
    --new=$cidata_part:219136:227327\
    --change-name=$cidata_part:CIDATA\
    --new=$rootfs_part::\
    --attributes=$rootfs_part:set:2

mount_image "$disk_image" "$rootfs_part"

rootfs_dev="/dev/mapper/${loop_p1%%[0-9]}$rootfs_part"
u_boot_dev="/dev/mapper/${loop_p1%%[0-9]}$u_boot_part"
cidata_dev="/dev/mapper/${loop_p1%%[0-9]}$cidata_part"
uefi_dev="/dev/mapper/${loop_p1%%[0-9]}$uefi_part"

# Re-generate initrd
create_initrd $rootfs_path "/mnt/jammy.rootfs" "/home/alex/work/beaglev/linux/build_starlight_ubuntu" "5.15.0-rc7-starlight+" "5.13.0-1004-generic"

exit 0

dd if=$rootfs_path of="$rootfs_dev"
#resize2fs "$rootfs_dev"
dd if=u-boot/u-boot.itb of="$u_boot_dev"
dd if=rootfs/jammy.cidata of="$cidata_dev"
mkfs.vfat -F 32 -n UEFI "$uefi_dev"

kpartx -ds "$disk_image"
