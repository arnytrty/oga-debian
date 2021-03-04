# oga-debian
oga-debian is Debain port for ODROID GO series, supported devices are:

| ODROID          | Progress   |
|:---------------:| ----------:|
| GO              | NOT TESTED |
| GO ADVANCE V1.0 | NOT TESTED |
| GO ADVANCE V1.1 | WORKING    |
| GO SUPER        | NOT TESTED |

*any commit or test result welcomed.*

---

# Prebuild Image
You can download prebuild image [HERE](http://web-18atrtuseka.panska.cz/odroidfiles/oga-debian.img), its hosted on my school's server. More Information about image:
```
Build Date:     2021.2.2

MD5 checksum:       07a298c086137d4403f6e5fd7bf6634d
SHA512 checksum:    4a27f102b30c35812505a850e673931b455b0c3d595fb2dc44ac016aa7cc7a17621f62f7209172c358045d5c071e821c2dea13067c565543a0ebd64f7ff4f9d2

Kernel:     4.4.189 aarch64
Debian:     Buster 10

User:       root
Password:   odroid
```

## After Installation
### Change Password
*odroid* is not the most secure password.
```bash
passwd
```

### Resitze Partition
In order to use full capacity of your sd card, you need to expand rootfs partiiton (*in default, its about 700M in size*).
First you need to resize the partition, you can do it automatically with this command:
```bash
fdisk /dev/mmcblk0 << EOF
d
2
n
p
2
262144

w
EOF
```
This will remove second partion on device mmcblk0 (sd card) and re-create it with **initial offset 262144 blocks** (this is important, there is boot sector in 0-262143, you can check your offset by `fdisk -l` but it should be the same).
After, it will write the changes to device, technicallly just rewriting end block of partition, *without affecting rootfs inside*.

**Then you need to resize the filesystem**:
```bash
resize2fs /dev/mmcblk0p2
```

After those steps are done, you can reboot and check the change with `lsblk`:
```bash
reboot

lsblk
```

### Configure Power Button Action
Because there was problem with logind power key handling (after wakeup instantly goes to sleep again), now its in acpi hands.
This step can be skipped if you planning install any desktop enviroment (GNOME, MATE, LXDE, ..)(they have their own configs and powermanagers).

You can change powerkey action by editing `/etc/acpi/odroidgoa-pwrbtn.sh`:
```bash
nano /etc/acpi/odroidgoa-pwrbtn.sh
``` 
There is few options that you can uncomment by removing **#** on the start of the line, but technically you can put here anything you want.
Example:
```bash
# systemctl poweroff # for poweroff
systemctl suspend # for suspend (ram sleep)
# systemctl hibernate # for hubernation (disk sleep)
```
*For hibernation you need swap partition (usually 2 times amount of ram)*

### Connecting to WiFi
First, create configuration using **wpa_passphrase** and redirect it to file:
```bash
wpa_passphrase SSID PASSWORD > /etc/wpa_supplicant/wifi.conf
```

Now start **wpa_supplicant** with that configuration:
```bash
wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wifi.conf
```

And run **dhclient** to receieve ip, mask and default gateway:
```
dhclient wlan0
```

### Change Keyboard Layout
Install **console-setup** and **keyboard-configuration**, popup about keyboard configuration should show.
```bash
apt install console-setup keyboard-configuration
```
If not, then write:
```
dpkg-reconfigure keyboard-configuration
```

---

# Build Image Yourself
First, download this repository:
```bash
git clone https://github.com/arnytrty/oga-debian.git --depth 1
cd oga-debian
```

To build the image, run 7 stages one after other (*IN ORDER*, *ROOT PREMITION NEEDED*). **Look for errors, you will need lot of libraries and dependencies**, how to clean failed attempt is listed below.
```bash
sudo ./01-prepare-toolchain.sh
sudo ./02-build-kernel.sh
sudo ./03-build-uboot.sh
sudo ./04-debootstrap-debian.sh
sudo ./05-build-uinitrd.sh
sudo ./06-create-image.sh
sudo ./07-cleanup.sh
```

Then you can flash your image to sd card by (**be careful with dd, make sure you select right /dev/sd**):
```bash
sudo dd if=oga-debian.img of=/dev/sdb status=progress
```

---

# Stages
What each stage do, how to clear it on failed attempt:
*Useful links are as comments in the scripts.*

## 01-prepare-toolchain
Download and install linaro-6.3.1- toolchain to `/opt/toolchains/`.
You can remove it by:
```bash
sudo rm /opt/toolchains -rf
```

## 02-build-kernel
Download kernel source from source, set DWC2 as module, build the kernel and copy binaries to run folder.
You can remove build by:
```bash
sudo rm linux -rf
sudo rm lib -rf
sudo rm Image rk3326-odroidgo*.dtb
```

## 03-build-uboot
Download u-boot from source, compile it and copy images to run folder.
You can remove build files by:
```bash
sudo rm u-boot -rf
sudo rm idbloader.img trust.img uboot.img
```

## 04-debootstrap-debian
Debootstrap debian (arm64), install **acpid bash-completion wpasupplicant**, set hostname to **oga-debian**, change root password to **odroid**.
Disable powerkey handle by logind and setup acpi script `/etc/acpi/odroidgoa-pwrbtn.sh` (default no action).
Then configures `/lib/systemd/system-sleep/sleep` to automaticly remove **esp8089** and **dwc2** when suspend and load them when wake up (**this is because esp8089 cause kernell panic on wake up and dwc2 wont wake at all**, forum thread link is in the script).
Makes boot automount on boot by `/etc/fstab`, make roots terminal colorized, copy lib files from previous stage, remove unwanted files and creates a tarball.
You can remove build files by:
```bash
sudo rm debian-rootfs -rf
sudo rm debian-rootfs.tar
```

## 05-build-uinitrd
Build **Initramfs** image, by using `debian-rootfs` folder created step before.
Nothing should go wrong in this step, but there is the cleanum command:
```bash
sudo rm uInitrd
```

## 06-create-image
Creates Image from files, using loopback device. Copy everything to place and create `boot.ini` with propper UUID.
You can remove the image by:
```bash
sudo rm oga-debian.img
```

## 07-cleanup
Clean everything :D, keep only the scripts and the image (even toolchain is removed).
If this goes wrong there is no way back.

---

special thanks to @joy from Odroid forum, who helps me with the wifi & usb stuff.
