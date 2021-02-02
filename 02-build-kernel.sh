#!/bin/bash

# useful links
# https://wiki.odroid.com/odroid_go_advance/build_kernel

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export PATH=/opt/toolchains/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/:$PATH

source ~/.bashrc

git clone https://github.com/hardkernel/linux.git -b odroidgoA-4.4.y --depth 1
cd linux

make odroidgoa_defconfig
sed -i 's/CONFIG_USB_DWC2=y/CONFIG_USB_DWC2=m/g' .config

make -j4

cp arch/arm64/boot/Image arch/arm64/boot/dts/rockchip/rk3326-odroidgo*.dtb ../
make modules_install ARCH=arm64 INSTALL_MOD_PATH=../

cd ..
