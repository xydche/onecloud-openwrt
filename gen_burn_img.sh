#!/bin/bash
sudo apt-get install img2simg
./AmlImg unpack ./uboot.img burn/
gzip -dk openwrt/bin/targets/*/*/*.gz

diskimg_path="openwrt/bin/targets/*/*/*.img"
boot_img_name="openwrt.img"
boot_img_mnt="xd"
rootfs_img_mnt="img"
prefix=$(ls $diskimg_path | sed 's/\.img$//')
burnimg_name="${prefix}.burn.img"

diskimg=$(ls -1 $diskimg_path | head -n 1)
loop=$(sudo losetup --find --show --partscan "$diskimg" | sed 's/[^[:print:]]//g')

if [ -z "$loop" ]; then
  echo "Error: Failed to setup loop device."
  exit 1
fi

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

sudo cp -rp ${rootfs_img_mnt}/* "${boot_img_mnt}"
sudo sync

sudo umount "${boot_img_mnt}" || true
sudo umount "${rootfs_img_mnt}" || true
rm -rf "${boot_img_mnt}" "${rootfs_img_mnt}"

sudo img2simg "${loop}p1" burn/boot.simg
sudo img2simg "${boot_img_name}" burn/rootfs.simg
sudo rm -f "${boot_img_name}"

sudo losetup -d "$loop" || true

printf "PARTITION:boot:sparse:boot.simg\nPARTITION:rootfs:sparse:rootfs.simg\n" >> burn/commands.txt

./AmlImg pack "${burnimg_name}" burn/
sha256sum "${burnimg_name}" > "${burnimg_name}.sha"
xz -9 --threads=0 --compress "${burnimg_name}"
rm -rf burn
rm ${diskimg_path}
echo "Script execution completed."
