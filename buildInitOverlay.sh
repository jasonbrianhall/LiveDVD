# This file is meant to be sourced and not ran directly.

	cat << EOF > init
#!/bin/busybox sh

# Dump to sh if something fails
error() {
	echo "Jumping into the shell..."
	setsid cttyhack sh
}
EOF

if [ $overlaybuild -eq 1 ]; then
	cat << EOF >> init
ignore() {
	echo "Ignoring Modprobe Error"
}


source ./modprobe.sh || ignore > /dev/null 2> /dev/null
EOF
fi

cat << EOF >> init
# Populate /bin with binaries from busybox
/bin/busybox --install /bin || error

mkdir -p /proc || error
mount -t proc proc /proc || error

mkdir -p /sys || error
mount -t sysfs sysfs /sys || error

mkdir -p /sys/dev || error
mkdir -p /var/run || error
mkdir -p /dev || error

mkdir -p /dev/pts || error
mount -t devpts devpts /dev/pts || error

# Populate /dev
mdev -s

mkdir -p /newroot || error
mount -t tmpfs tmpfs /newroot || error

EOF
if [ $overlaybuild -eq 1 ]; then
	cat << EOF >> init

mkdir -p /cdroot || error
mkdir -p /overlay || error

mkdir -p /newroot/upper || error
mkdir -p /newroot/workdir || error

mount /dev/sr0 /cdroot || error

mknod /dev/loop0 b 7 0

mkdir -p /squash
EOF
if [ $luksbuild -eq 1 ]; then
cat << EOF >> init
/sbin/cryptsetup luksOpen /cdroot/newroot/encrypted cr_temp || error
mount /dev/mapper/cr_temp /squash -t squashfs
EOF
else
cat << EOF >> init
mount /cdroot/newroot/root.squash /squash -t squashfs
EOF
fi
else
	cat << EOF >> init
echo "Extracting rootfs... "
cat rootfs.tar | tar -x -f - -C /newroot || error

mount --move /sys /newroot/sys
mount --move /proc /newroot/proc
mount --move /dev /newroot/dev
EOF
fi
if [ $overlaybuild -eq 1 ]; then
	cat << EOF >> init
mount -t overlay -o lowerdir=/squash,upperdir=/newroot/upper,workdir=/newroot/workdir none /overlay || error

mount --move /sys /overlay/sys || error
mount --move /proc /overlay/proc || error

EOF
	if [ $skipdhcpscript -eq 0 ]; then
		cat << EOF >> init
# DHCP for RHEL
cp ../rc/rc.local etc/rc.d/rc.local
chmod +x etc/rc.d/rc.local
EOF
	fi


	if [ $rootbuild -eq 1 ]; then
		cat << EOF >> init
sed -i '/^root/d' /overlay/etc/shadow
EOF
		salt=`date | md5sum | awk '{print $1}'`
		temp=$(echo "root:`openssl passwd -6 -salt $salt $rootpassword`:18368:0:99999:7:::")
		echo "echo '$temp' >> /overlay/etc/shadow" >> init
	fi
	if [ $selinuxenabled -eq 0 ]; then
		cat << EOF >> init
echo "SELINUX=disabled" > /overlay/etc/selinux/config
EOF
	fi
	cat << EOF >> init
		echo "" > /overlay/etc/fstab
EOF
fi
cat << EOF >> init
exec switch_root /overlay /sbin/init || error
EOF
