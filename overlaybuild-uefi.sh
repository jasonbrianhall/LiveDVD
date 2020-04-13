#!/bin/bash

#!!!! DON'T USE THIS; THIS IS TEST CODE !!!!

pushd newroot
mkdir ../grub-overlay/newroot -p
rm ../grub-overlay/newroot/* -R -f
cp ../rc.local etc/rc.d/rc.local -f
chmod +x etc/rc.d/rc.local
echo "SELINUX=disabled" > etc/selinux/config
echo "" > etc/fstab
mksquashfs . ../grub-overlay/newroot/root.squash
popd

pushd overlayfs
dracut -i $(pwd)/modprobe.sh modprobe.sh -i $(pwd)/myinit myinit -i $(pwd)/bin/busybox usr/bin/busybox ../grub-overlay/boot/rhel8/initramfs.gz -f
popd

rm efi.img -f
rm grub-overlay/efi.img -f
source mkimage.sh
rsync -avl isolinux grub-overlay/
cp efi.img grub-overlay/ -R -f
xorriso -as mkisofs -o result/test.iso -isohybrid-mbr isolinux/isohdpfx.bin -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e efi.img -no-emul-boot -isohybrid-gpt-basdat grub-overlay/
#grub2-mkrescue -o result/test.iso grub-overlay/

