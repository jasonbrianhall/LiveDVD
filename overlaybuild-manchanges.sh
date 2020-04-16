#!/bin/bash

#rm grub/newroot -R -f
rm grub-overlay/newroot -R -f

umount overlayroot
umount overlay


mkdir -p overlayroot
mount -t tmpfs tmpfs overlayroot

mkdir -p overlayroot/upper
mkdir -p overlayroot/workdir

mkdir -p overlay
mount -t overlay -o lowerdir=newroot,upperdir=overlayroot/upper,workdir=overlayroot/workdir none overlay 




pushd overlay
rm ../grub-overlay/newroot/* -R -f
mkdir ../grub-overlay/newroot -p
rsync -avl /usr/lib/modules/ usr/lib/modules/
rsync -avl /lib/modules/ lib/modules/

cp ../rc/rc.local etc/rc.d/local
echo "SELINUX=disabled" > etc/selinux/config
mksquashfs . ../grub-overlay/newroot/root.squash
popd

umount overlayroot
umount overlay


pushd overlayfs
dracut -i $(pwd)/../rc/rc.local /etc/rc.d/rc.local -i $(pwd)/modprobe.sh modprobe.sh -i $(pwd)/myinit myinit -i $(pwd)/bin/busybox usr/bin/busybox ../grub-overlay/boot/rhel8/initramfs.gz -f
popd

grub2-mkrescue -o result/overlay.iso grub-overlay/

