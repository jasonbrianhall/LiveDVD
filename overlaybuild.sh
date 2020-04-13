#!/bin/bash

#rm grub/newroot -R -f

pushd newroot
rm ../grub-overlay/newroot/* -R -f
mkdir ../grub-overlay/newroot -p
#cp ../rc.local etc/rc.d/rc.local -f
#chmod +x etc/rc.d/rc.local
#echo "SELINUX=disabled" > etc/selinux/config
#echo "" > etc/fstab
mksquashfs . ../grub-overlay/newroot/root.squash
popd

pushd overlayfs
dracut -i $(pwd)/../rc/rc.local /etc/rc.d/rc.local -i $(pwd)/modprobe.sh modprobe.sh -i $(pwd)/myinit myinit -i $(pwd)/bin/busybox usr/bin/busybox ../grub-overlay/boot/rhel8/initramfs.gz -f
popd

grub2-mkrescue -o result/overlay.iso grub-overlay/

