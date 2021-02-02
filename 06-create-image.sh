#!/bin/bash

# useful links
# https://wiki.odroid.com/odroid_go_advance/build_uboot
# https://www.thegeekdiary.com/how-to-create-virtual-block-device-loop-device-filesystem-in-linux/

# create loop device
dd if=/dev/zero of=oga-debian.img bs=10M count=99 status=progress
losetup -fP oga-debian.img

export LBD_DEV=$(losetup -a | grep oga-debian.img | cut -d ':' -f 1)

# create partition
fdisk $LBD_DEV << "EOF"
n
p
1
32768
262143
t
b
n
p
2
262144

t
2
83
w
EOF

# format partition
mkfs.vfat $(echo $LBD_DEV)p1
fatlabel $(echo $LBD_DEV)p1 boot
mkfs.ext4 $(echo $LBD_DEV)p2
e2label $(echo $LBD_DEV)p2 rootfs

# mount partition
mkdir -p mountBOOT
mount $(echo $LBD_DEV)p1 mountBOOT
mkdir -p mountROOTFS
mount $(echo $LBD_DEV)p2 mountROOTFS

# get uuid of rootfs partition
export ROOTFS_UUID=$(blkid -s UUID -o value $(echo $LBD_DEV)p2)

# copy everyting to place
cp uInitrd rk3326-odroidgo*.dtb Image mountBOOT/ && sync
tar -xvf debian-rootfs.tar -C mountROOTFS && sync
cp -r lib/* mountROOTFS/lib && sync

# create boot.ini
echo "odroidgoa-uboot-config" >> mountBOOT/boot.ini
echo "########################################################################" >> mountBOOT/boot.ini
echo "# Changes made to this are overwritten every time there's a new upgrade" >> mountBOOT/boot.ini
echo "# To make your changes permanent change it on" >> mountBOOT/boot.ini
echo "# boot.ini.default" >> mountBOOT/boot.ini
echo "# After changing it on boot.ini.default run the bootini command to" >> mountBOOT/boot.ini
echo "# rewrite this file with your personal permanent settings." >> mountBOOT/boot.ini
echo "########################################################################" >> mountBOOT/boot.ini
echo "" >> mountBOOT/boot.ini
echo "# Boot Arguments" >> mountBOOT/boot.ini
echo "setenv bootargs \"root=UUID='$ROOTFS_UUID' rootwait rw fsck.repair=yes net.ifnames=0 fbcon=rotate:3 console=/dev/ttyFIQ0\"" >> mountBOOT/boot.ini
echo "" >> mountBOOT/boot.ini
echo "# Booting" >> mountBOOT/boot.ini
echo "setenv loadaddr \"0x02000000\"" >> mountBOOT/boot.ini
echo "setenv initrd_loadaddr \"0x01100000\"" >> mountBOOT/boot.ini
echo "setenv dtb_loadaddr \"0x01f00000\"" >> mountBOOT/boot.ini
echo "" >> mountBOOT/boot.ini
echo "load mmc 1:1 ${loadaddr} Image" >> mountBOOT/boot.ini
echo "load mmc 1:1 ${initrd_loadaddr} uInitrd" >> mountBOOT/boot.ini
echo "" >> mountBOOT/boot.ini
echo "if test ${hwrev} = 'v11'; then" >> mountBOOT/boot.ini
echo "load mmc 1:1 ${dtb_loadaddr} rk3326-odroidgo2-linux-v11.dtb" >> mountBOOT/boot.ini
echo "elif test ${hwrev} = 'v10-go3'; then" >> mountBOOT/boot.ini
echo "load mmc 1:1 ${dtb_loadaddr} rk3326-odroidgo3-linux.dtb" >> mountBOOT/boot.ini
echo "else" >> mountBOOT/boot.ini
echo "load mmc 1:1 ${dtb_loadaddr} rk3326-odroidgo2-linux.dtb" >> mountBOOT/boot.ini
echo "fi" >> mountBOOT/boot.ini
echo "" >> mountBOOT/boot.ini
echo "booti ${loadaddr} ${initrd_loadaddr} ${dtb_loadaddr}" >> mountBOOT/boot.ini

# umount & remove loop device
umount mount*
rm -rf mount*

losetup -d $LBD_DEV
