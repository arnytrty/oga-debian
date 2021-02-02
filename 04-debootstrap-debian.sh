#!/bin/bash

# uselful links
# https://forum.odroid.com/viewtopic.php?f=196&t=41577
# https://wiki.debian.org/Arm64Port#tarball_rootfs
# https://a-delacruz.github.io/debian/debian-arm64.html

# plain debootstrap
debootstrap --arch=arm64 --foreign buster debian-rootfs
cp -av /usr/bin/qemu-aarch64-static debian-rootfs/usr/bin
cp -av /run/systemd/resolve/stub-resolv.conf debian-rootfs/etc/resolv.conf

chroot debian-rootfs << "EOT"
/debootstrap/debootstrap --second-stage

# bonus packages
apt install -y acpid bash-completion wpasupplicant

# rename machine
echo "oga-debian" > /etc/hostname

# make power button handle by acpid
sed -i 's/#HandlePowerKey=poweroff/HandlePowerKey=ignore/g' /etc/systemd/logind.conf

echo "event=button/power" >> /etc/acpi/events/odroidgoa-pwrbtn
echo "action=/etc/acpi/odroidgoa-pwrbtn.sh" >> /etc/acpi/events/odroidgoa-pwrbtn

echo \#\!/bin/bash >> /etc/acpi/odroidgoa-pwrbtn.sh
echo "# dont uncomment those if you have desktop enviroment, it should be automated" >> /etc/acpi/odroidgoa-pwrbtn.sh
echo "# systemctl poweroff # for poweroff" >> /etc/acpi/odroidgoa-pwrbtn.sh
echo "# systemctl suspend # for suspend (ram sleep)" >> /etc/acpi/odroidgoa-pwrbtn.sh
echo "# systemctl hibernate # for hibernation (disk sleep)" >> /etc/acpi/odroidgoa-pwrbtn.sh
chmod +x /etc/acpi/odroidgoa-pwrbtn.sh

# configure (wifi & usb modules to work after suspend)
echo \#\!/bin/bash >> /lib/systemd/system-sleep/sleep
echo "case \$1 in" >> /lib/systemd/system-sleep/sleep
echo "pre)" >> /lib/systemd/system-sleep/sleep
echo "rmmod esp8089" >> /lib/systemd/system-sleep/sleep
echo "modprobe -r dwc2" >> /lib/systemd/system-sleep/sleep
echo ";;" >> /lib/systemd/system-sleep/sleep
echo "post)" >> /lib/systemd/system-sleep/sleep
echo "modprobe -r dwc2" >> /lib/systemd/system-sleep/sleep
echo "modprobe -i dwc2" >> /lib/systemd/system-sleep/sleep
echo "modprobe -i esp8089" >> /lib/systemd/system-sleep/sleep
echo ";;" >> /lib/systemd/system-sleep/sleep
echo "esac" >> /lib/systemd/system-sleep/sleep
chmod a+x /lib/systemd/system-sleep/sleep

echo "dwc2" >> /etc/modules-load.d/modules.conf

# mount boot partition on boot
echo "/dev/mmcblk0p1 /boot vfat defaults 0 1" >> /etc/fstab

# configure root password
passwd << "EOT2"
odroid
odroid
EOT2

# make root terminal colorized
cp /etc/skel/.bashrc /root/.bashrc
sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' /root/.bashrc

# remove unwanted files
rm -rf /usr/share/man/* /usr/share/groff/* /usr/share/info/*
rm -rf /usr/share/lintian/* /usr/share/linda/* /var/cache/man/*
rm -rf /debootstrap

EOT

# copy lib from compiled kernel
cp -r lib/* debian-rootfs/lib/

# tar filesystem and move to main directory
cd debian-rootfs

# umount everything ?! on my machine wasnt unmounted proc
umount -l *

tar -cvf debian-rootfs.tar *
cd ..
mv debian-rootfs/debian-rootfs.tar .
