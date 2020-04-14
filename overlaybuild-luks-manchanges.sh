#/bin/bash

PASSWORD="Password1"
#USERPASSWORD="ChangeMe"
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
mkdir ../grub-overlay/newroot -p
rm ../grub-overlay/newroot/* -R -f
rsync -avl /usr/lib/modules/ usr/lib/modules/
rsync -avl /lib/modules/ lib/modules/
cp ../rc/rc.local etc/rc.d/local
echo "SELINUX=disabled" > etc/selinux/config
#sed -i '/^root/d' etc/shadow 
#echo "root:$(mkpasswd -m sha-512 <<< "$USERPASSWORD")::0:99999:7::::" >> /etc/shadoow
cat << EOF > etc/inittab
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

umount overlayroot
umount overlay

pushd overlayfs
dracut -i $(pwd)/../rc/rc.local /etc/rc.d/rc.local -i /sbin/cryptsetup /sbin/cryptsetup -i $(pwd)/modprobe.sh modprobe.sh -i $(pwd)/myinit2-encrypted myinit -i $(pwd)/bin/busybox usr/bin/busybox ../grub-overlay/boot/rhel8/initramfs.gz -f
popd

grub2-mkrescue -o result/overlay-luks.iso grub-overlay/

