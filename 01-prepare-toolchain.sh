#!/bin/bash

mkdir -p /opt/toolchains
wget https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz
tar Jxvf gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz -C /opt/toolchains/
rm gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz
