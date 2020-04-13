#!/bin/bash

BOOT_IMG_DATA=$(mktemp -d)
BOOT_IMG=$(mktemp -d)/efi.img
mkdir -p $(dirname $BOOT_IMG)

truncate -s 2880K $BOOT_IMG
mkfs.vfat $BOOT_IMG
mount $BOOT_IMG $BOOT_IMG_DATA
mkdir -p $BOOT_IMG_DATA/efi/boot

grub2-mkimage \
	-C xz -O x86_64-efi \
	-p /boot/grub \
	-o $BOOT_IMG_DATA/efi/boot/bootx64.efi boot linux search normal configfile part_gpt btrfs ext2 fat iso9660 loopback test keystatus gfxmenu regexp probe efi_gop efi_uga all_video gfxterm font echo read ls cat png jpeg halt reboot tftp part_msdos xfs linux

umount $BOOT_IMG_DATA
cp $BOOT_IMG .
rm -rf $BOOT_IMG_DATA
