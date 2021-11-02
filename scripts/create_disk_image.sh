#!/bin/bash

image_name="$1"
rootfs_path="$2" # it will get modified in-place
cidata_path="$3"
uboot_path="$4"

image_size=4290755584

create_empty_image_name() {
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

rm -f "$image_name"
create_empty_image_name "$image_name"
#sgdisk --zap-all "$image_name"

rootfs_part="1"
cidata_part="12"
u_boot_part="14"
uefi_part="15"

sgdisk "${image_name}" \
    --set-alignment=2 \
    --new=$u_boot_part:2048:10239 \
    --change-name=$u_boot_part:loader2 \
    --typecode=$u_boot_part:ef02 \
    --new=$uefi_part:10240:219135 \
    --typecode=$uefi_part:ef00 \
    --new=$cidata_part:219136:227327 \
    --change-name=$cidata_part:CIDATA \
    --new=$rootfs_part:: \
    --attributes=$rootfs_part:set:2

mount_image "$image_name" "$rootfs_part"

rootfs_dev="/dev/mapper/${loop_p1%%[0-9]}$rootfs_part"
u_boot_dev="/dev/mapper/${loop_p1%%[0-9]}$u_boot_part"
cidata_dev="/dev/mapper/${loop_p1%%[0-9]}$cidata_part"
uefi_dev="/dev/mapper/${loop_p1%%[0-9]}$uefi_part"

dd if=$uboot_path of="$u_boot_dev"
dd if=$cidata_path of="$cidata_dev"
mkfs.vfat -F 32 -n UEFI "$uefi_dev"
# rootfs
mkfs.ext4 -F -b 4096 -i 8192 -m 0 -L "cloudimg-rootfs" -E resize=536870912 "$rootfs_dev"
mkdir -p /tmp/mnt_rootfs
mount $rootfs_path /tmp/mnt_rootfs
mkdir -p /tmp/mnt_dev_rootfs
mount $rootfs_dev /tmp/mnt_dev_rootfs
cp -a /tmp/mnt_rootfs/* /tmp/mnt_dev_rootfs/
umount /tmp/mnt_rootfs
umount /tmp/mnt_dev_rootfs

kpartx -ds "$image_name"
