#!/bin/bash

./AmlImg unpack ./uboot.img burn/
gunzip openwrt/bin/targets/*/*/*.gz

# 定义变量以增加代码的可读性和可维护性
diskimg_path="openwrt/bin/targets/*/*/*.img"
boot_img_name="openwrt.img"
boot_img_mnt="xd"
rootfs_img_mnt="img"
prefix=$(ls $diskimg_path | sed 's/\.img$//')
burnimg_name="${prefix}.burn.img"

# 安全地获取diskimg路径，避免命令注入
diskimg=$(ls -1 $diskimg_path | head -n 1)
loop=$(sudo losetup --find --show --partscan "$diskimg" | sed 's/[^[:print:]]//g')

# 检查loop设备是否成功设置
if [ -z "$loop" ]; then
  echo "Error: Failed to setup loop device."
  exit 1
fi

# 创建boot.img和挂载文件系统
dd if=/dev/zero of="${boot_img_name}" bs=1M count=600 status=progress
if [ $? -ne 0 ]; then
  echo "Error: Failed to create boot image."
  exit 1
fi

mkfs.ext4 "${boot_img_name}"
if [ $? -ne 0 ]; then
  echo "Error: Failed to format boot image."
  exit 1
fi

# 创建目录并挂载
mkdir -p "${boot_img_mnt}" "${rootfs_img_mnt}"
sudo mount "${boot_img_name}" "${boot_img_mnt}"
if [ $? -ne 0 ]; then
  echo "Error: Failed to mount boot image."
  exit 1
fi

sudo mount "${loop}p2" "${rootfs_img_mnt}"
if [ $? -ne 0 ]; then
  echo "Error: Failed to mount rootfs partition."
  exit 1
fi

# 复制文件并同步
sudo cp -rp ${rootfs_img_mnt}/* "${boot_img_mnt}"
sudo sync

# 从挂载点卸载
sudo umount "${boot_img_mnt}" || true
sudo umount "${rootfs_img_mnt}" || true
rm -rf "${boot_img_mnt}" "${rootfs_img_mnt}"

# 处理分区并打包
sudo img2simg "${loop}p1" burn/boot.simg
sudo img2simg "${boot_img_name}" burn/rootfs.simg
sudo rm -f "${boot_img_name}"

# 释放loop设备
sudo losetup -d "$loop" || true

# 添加命令到文件
printf "PARTITION:boot:sparse:boot.simg\nPARTITION:rootfs:sparse:rootfs.simg\n" >> burn/commands.txt

# 打包并计算校验和
./AmlImg pack "${burnimg_name}" burn/
sha256sum "${burnimg_name}" > "${burnimg_name}.sha"
xz -9 --threads=0 --compress "${burnimg_name}"
rm -rf burn
echo "Script execution completed."