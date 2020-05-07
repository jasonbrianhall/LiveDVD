cat << EOF > init
#!/bin/bash

# Dump to sh if something fails
error() {
	echo "Jumping into the shell..."
	setsid cttyhack sh
}


mkdir -p /proc
mount -t proc proc /proc

mkdir -p /sys
mount -t sysfs sysfs /sys

mkdir -p /sys/dev
mkdir -p /var/run
mkdir -p /dev

mkdir -p /dev/pts
mount -t devpts devpts /dev/pts

mount -t devtmpfs none /dev

mkdir -p /newroot
mount -t tmpfs tmpfs /newroot || error

echo "Extracting rootfs... "
cat rootfs.tar | tar -x -f - -C /newroot || error

mount --move /sys /newroot/sys
mount --move /proc /newroot/proc
mount --move /dev /newroot/dev

exec /sbin/chroot /overlay /sbin/init

EOF
