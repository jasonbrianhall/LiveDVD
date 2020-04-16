cat << EOF > init
#!/bin/busybox sh

# Dump to sh if something fails
error() {
	echo "Jumping into the shell..."
	setsid cttyhack sh
}

# Populate /bin with binaries from busybox
/bin/busybox --install /bin

mkdir -p /proc
mount -t proc proc /proc

mkdir -p /sys
mount -t sysfs sysfs /sys

mkdir -p /sys/dev
mkdir -p /var/run
mkdir -p /dev

mkdir -p /dev/pts
mount -t devpts devpts /dev/pts

# Populate /dev
echo /bin/mdev > /proc/sys/kernel/hotplug
mdev -s

mkdir -p /newroot
mount -t tmpfs tmpfs /newroot || error

echo "Extracting rootfs... "
cat rootfs.tar | tar -x -f - -C /newroot || error

mount --move /sys /newroot/sys
mount --move /proc /newroot/proc
mount --move /dev /newroot/dev

exec switch_root /newroot /sbin/init || error
EOF
