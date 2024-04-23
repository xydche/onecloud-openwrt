#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

sed -i '/KERNEL_PATCHVER/c KERNEL_PATCHVER:=5.15' target/linux/x86/Makefile

wget -O tmp/adg.tar.gz https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_amd64.tar.gz
tar -zxvf tmp/adg.tar.gz -C tmp/
mkdir -p files/usr/bin
mv tmp/AdGuardHome/AdGuardHome files/usr/bin/
chmod +x files/usr/bin/AdGuardHome
ls files/usr/bin/
