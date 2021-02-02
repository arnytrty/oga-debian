#!/bin/bash

# useful links
# https://wiki.odroid.com/odroid_go_advance/build_uboot

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export PATH=/opt/toolchains/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/:$PATH

source ~/.bashrc

git clone https://github.com/hardkernel/u-boot.git -b odroidgoA-v2017.09 --depth 1

cd u-boot
./make.sh odroidgoa
cd ..

cp u-boot/sd_fuse/idbloader.img u-boot/sd_fuse/trust.img u-boot/sd_fuse/uboot.img .
