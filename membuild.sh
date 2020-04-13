#!/bin/bash

rm grub/newroot -R -f

mkdir -p overlayroot
mount -t tmpfs tmpfs overlayroot

mkdir -p overlayroot/upper
mkdir -p overlayroot/workdir

mkdir -p overlay
mount -t overlay -o lowerdir=newroot,upperdir=overlayroot/upper,workdir=overlayroot/workdir none overlay 


pushd overlay
cp ../rc/rc.local etc/rc.d/local
echo "SELINUX=disabled" > etc/selinux/config
tar cf ../initramfs/rootfs.tar --exclude="boot" .
popd

umount overlayroot
umount overlay

pushd initramfs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../grub-memdisk/boot/rhel8/initramfs.gz
popd

grub2-mkrescue -o result/membuild.iso grub-memdisk/

