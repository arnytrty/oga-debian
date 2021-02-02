#!/bin/bash

# useful links
# https://wiki.odroid.com/odroid_go_advance/build_uboot

chroot debian-rootfs << "EOT"

apt install -y u-boot-tools initramfs-tools

update-initramfs -c -t -k "4.4.189"
mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n uInitrd -d /boot/initrd.img-4.4.189 /boot/uInitrd-4.4.189

EOT

cp debian-rootfs/boot/uInitrd-4.4.189 uInitrd
