#/bin/bash

PASSWORD="Password1"

pushd newroot
mkdir ../grub-overlay/newroot -p
rm ../grub-overlay/newroot/* -R -f
#cp ../rc.local etc/rc.d/rc.local -f
#chmod +x etc/rc.d/rc.local
#echo "SELINUX=disabled" > etc/selinux/config
#echo "" > etc/fstab
mksquashfs . ../grub-overlay/newroot/root.squash
pushd ../grub-overlay/newroot/
dd if=/dev/zero of=encrypted bs=1M count=16
cat root.squash >> encrypted
echo -n "$PASSWORD" | cryptsetup luksFormat encrypted -
cryptsetup luksOpen encrypted cr_temp <<< $PASSWORD
dd if=root.squash of=/dev/mapper/cr_temp
cryptsetup luksClose cr_temp
rm root.squash -f
popd
popd

pushd overlayfs
dracut -i $(pwd)/../rc/rc.local /etc/rc.d/rc.local -i /sbin/cryptsetup /sbin/cryptsetup -i $(pwd)/modprobe.sh modprobe.sh -i $(pwd)/myinit-encrypted myinit -i $(pwd)/bin/busybox usr/bin/busybox ../grub-overlay/boot/rhel8/initramfs.gz -f
popd

grub2-mkrescue -o result/overlay-luks.iso grub-overlay/

