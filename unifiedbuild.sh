#!/bin/bash

membuild=0
overlaybuild=0
luksbuild=0
selinuxenabled=0
useguestfish=0
luksbuild=0
usekernel=0
usekernelversion=0
rootbuild=0
grubtitle="Red Hat Enterprise Linux"
grubtitledefault="Red Hat Enterprise Linux"
producttype="rhel8"
producttypedefault="rhel8"
skipdhcpscript=0
productentered=0
originaldirectory=$(pwd)
skipmakingsquash=0
useyum=0
CDLABELFound=0
adddriver=0
#File Usage
function usage()
{
        echo "usage: 
	-m | --membuild
		Memory build; Put everything in memory (Requires atleast twice as much memory as the ISO image); makes a TAR from newroot
	-o | --overlaybuild
		Overlay build; Only put changes in memory; makes a SquashFS from newroot; may not support SELINUX
	-s | --selinux
		Keep SELinux Settings
	-l | --luks Password
		Makes an Encrypted DVD with Set Password
	-r | --rootpassword Password
		Attempts to Change Root Password
	-g | --guestfish imagename
		Mounts a .raw, .qcow2, or other supported image and makes a Squashfs (support XATTR which may allow it to boot with SELinux); only supported with -o
	-k | --kernel imagename
		Copy this kernel (program assumes you have the kernel in the right location)
        -K | --kernelversion imagename
                Try to use this kernel version with dracut
	--add-drivers 
		Add these drivers to dracut
	-t | --title Software Title (Defaults to \"$grubtitledefault\")
		Creates a GRUB Menu Title
	-p | --producttype name 
		Creates a Directory in Grub for OS Type (Defaults to \"$producttypeedefault\")
	-q | --quick 
		Skips making squash or initrd for memdisk (assumes already made from previous run); useful for making changes to the code
	-y | --yum 
		Makes initrd using yum (broken, don't use)
	-V | --cdlabel 
		CD Label (if undefined, defaults to product type)
	-h | --help
		This Help File"				
}

function yumcommands() {
	if [[ -d ../temp ]]; then
		rm ../temp -R -f
	fi
	mkdir ../temp
	source ../mkimage-yum.sh -p "kernel vim-minimal vim-common cryptsetup" -t $(pwd)/../temp
	cp ../rc/rc.local ../temp/etc/rc.d/rc.local
	chmod +x ../temp/etc/rc.d/rc.local
	cp modprobe.sh ../temp/modprobe.sh
	cp init ../temp/init
	pushd ../temp
	find . | cpio --null -ov --format=newc | gzip -9 > ../grub-overlay/boot/$producttype/initramfs.gz
	popd	
}

function buildInitOverlay() {
	source $originaldirectory/buildInitOverlay.sh
}

function buildInitMem() {
	source $originaldirectory/buildInitMem.sh
}


function buildGrub() {
	source $originaldirectory/buildGrub.sh
}


function error() {
	echo "An Error Occurred; Exiting"
	exit 1
}



function mountOverlay()
{
	echo "Mounting Overlay Filesystem"

	umount overlayroot
	umount overlay
	rm -R -f overlayroot
	rm -R -f overlay
	mkdir -p overlayroot || error
	mount -t tmpfs tmpfs overlayroot || error

	mkdir -p overlayroot/upper || error
	mkdir -p overlayroot/workdir || error

	mkdir -p overlay || error
	mount -t overlay -o lowerdir=newroot,upperdir=overlayroot/upper,workdir=overlayroot/workdir none overlay  || error
	return 0
}

function unmountOverlay()
{
	echo "Unmounting Overlay Filesystem"

	umount overlayroot || error
	umount overlay  || error
	return 0
}


# Checking Command Line Parameters
if [ $# -gt 0 ]; then
        while [ "$1" != "" ]; do
                case $1 in
                        -m | --membuild )
                                        membuild=1
                                        ;;
                        -o | --overlaybuild )
                                        overlaybuild=1
                                        ;;
                        -s | --selinux )
                                        selinuxenabled=1
                                        ;;

                        -l | --luks )   shift
                                        luksbuild=1
					lukspassword=$1
                                        ;;
                        -r | --rootpassword )   shift
                                        rootbuild=1
					rootpassword=$1
                                        ;;
                        -g | --guestfish )   shift
                                        useguestfish=1
					guestfishimage=$1
                                        ;;
                        -k | --kernel )   shift
                                        usekernel=1
					kernellocation=$1
                                        ;;
                        -K | --kernelversion )   shift
                                        usekernelversion=1
                                        kernelversion=$1
                                        ;;
                        --add-drivers )   shift
                                        adddriver=1
                                        driverdata=$1
                                        ;;
                        -t | --title )   shift
					grubtitle=$1
                                        ;;
                        -p | --producttype )   shift
					producttype=$1
					productentered=1
					find grub-memdisk/* | grep -v "grub" | xargs -I xxx rm xxx -R -f
					find grub-overlay/* | grep -v "grub" | xargs -I xxx rm xxx -R -f
                                        ;;
                        -V | --cdlabel )   shift
					CDLABEL=$1
					CDLABELFound=1
					;;
			-d | --dhcp)
					skipdhcpscript=1
					;;
			-q | --quick)
					skipmakingsquash=1
					;;
			-y | --yum)
					useyum=1
					;;
                        -h | --help )   usage
                                        exit 1
                                        ;;
                        * )             usage
                                        exit 1
                                        ;;
                esac
                shift
        done
else
	usage
	exit 1
fi

if [ $CDLABELFound -eq 0 ]; then
	CDLABEL=$producttype
fi

if [ "$productentered" -eq 0 ] &&  [ "$usekernel" -eq 0 ]; then
	echo "No kernel option was detected; Make sure you put the kernel in the appropriate location or use -k.  If you don't have a kernel, product won't boot!!!"
fi


if [ "$productentered" -eq 1 ] &&  [ "$usekernel" -eq 0 ]; then
	echo "If using -p, you must use -k"
	exit 1
fi

if [ "$membuild" -eq 1 ] &&  [ "$overlaybuild" -eq 1 ]; then
	echo "Can't specify both membuild and overlaybuild"
	exit 1
fi

if [ "$membuild" -eq 1 ] ||  [ "$overlaybuild" -eq 1 ]; then
	if [ "$membuild" -eq 1 ]; then
		echo "Creating Membuild"
	else
		echo "Creating Overlay Build"
	fi
else
	echo "At least one of membuild and overlaybuild must be specified"
	exit 1
fi

if [ "$membuild" -eq 1 ]; then
	echo -e "In Membuild"
	mountOverlay
	if [ $skipmakingsquash -eq 0 ]; then
		pushd overlay
		echo -e "\nBuiding TAR Filesystem"
		echo "" > /etc/fstab
		if [ $selinuxenabled -eq 0 ]; then
			echo "SELINUX=disabled" > etc/selinux/config
		fi
		if [ $skipdhcpscript -eq 0 ]; then
			cp ../rc/rc.local etc/rc.d/rc.local
			chmod +x etc/rc.d/rc.local
		fi
		if [ $rootbuild -eq 1 ]; then
		
			sed -i '/^root/d' etc/shadow
			salt=`date | md5sum | awk '{print $1}'`
			echo "root:`openssl passwd -6 -salt $salt $rootpassword`:18368:0:99999:7:::" >> etc/shadow
		fi
	fi
		tar cf ../initramfs/rootfs.tar --exclude="boot" .
		popd
	echo -e "\nBuilding Initial RAM Disk"
	pushd initramfs
	buildInitMem
	chmod +x init
	if [ "$productentered" -eq 1 ]; then
		mkdir -p ../grub-memdisk/boot/$producttype/
		rm ../grub-memdisk/boot/$producttypedefault -R -f
	fi
	find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../grub-memdisk/boot/$producttype/initramfs.gz
	popd
	if [ $usekernel -eq 1 ]; then
		cp $kernellocation grub-memdisk/boot/$producttype/vmlinuz
	fi
	echo -e "\nBuilding GRUB"
	buildGrub 
	cp grub.cfg grub-memdisk/boot/grub/grub.cfg -f 
	echo -e "\nBuilding ISO"
	grub2-mkrescue -o result/membuild.iso grub-memdisk/ -V $CDLABEL
	echo -e "\n\nMemdisk Build Complete; saved to result/membuild.iso"
	unmountOverlay
elif [ "$useguestfish" -eq 0 ]; then
	echo -e "\nNot using guestfish"
	mountOverlay
	if [ $skipmakingsquash -eq 0 ]; then
		pushd overlay
		rm ../grub-overlay/newroot/* -R -f
		mkdir ../grub-overlay/newroot -p
		mksquashfs . ../grub-overlay/newroot/root.squash
		popd
		if [ "$luksbuild" -eq 1 ]; then
			pushd grub-overlay/newroot/
			dd if=/dev/zero of=encrypted bs=1M count=16
			cat root.squash >> encrypted
			echo -n "$lukspassword" | cryptsetup luksFormat encrypted -
			cryptsetup luksOpen encrypted cr_temp <<< $lukspassword
			dd if=root.squash of=/dev/mapper/cr_temp
			cryptsetup luksClose cr_temp
			rm root.squash -f
			popd
		fi
	fi
	buildInitOverlay
	chmod +x init
	mv init overlayfs -f
	pushd overlayfs
	mkdir -p ../grub-overlay/boot/$producttype
	if [ $useyum -eq 0 ]; then
		if [ -d temp ]; then
			rm temp -R -f
		fi
		mkdir temp
		pwd
		params="-i $(pwd)/../rc/rc.local /etc/rc.d/rc.local -i $(pwd)/modprobe.sh modprobe.sh -i /bin/chmod /bin/chmod -i $(pwd)/init myinit temp/initramfs.gz -f"
		if [ $adddriver -eq 1 ]; then
			#params="--drivers '$driverdata' $params"
			temp=""
			for x in $driverdata
			do
				temp="$temp -d $x"
			done
			params="$temp $params"
		fi
		echo "$params"
		if [ $usekernelversion -eq 0 ]; then
			dracut $params
		else
			params="$params $kernelversion"
			dracut $params
		fi
		pushd temp
		/usr/lib/dracut/skipcpio initramfs.gz  | gzip -d - | cpio -idv
		rm initramfs.gz
		rm init -f
		mv myinit init
		find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../../grub-overlay/boot/$producttype/initramfs.gz
		popd
		membuild=1
	else
		yumcommands
		membuild=1
	fi
	popd
	echo "Before usekernel"
	if [ $usekernel -eq 1 ]; then
		cp $kernellocation grub-overlay/boot/$producttype/vmlinuz
	fi
	buildGrub 
	cp grub.cfg grub-overlay/boot/grub/grub.cfg -f 
	grub2-mkrescue -o result/overlay.iso grub-overlay/ -V $CDLABEL
	echo -e "\n\nOverlay Build Complete; saved to result/overlay.iso"
	unmountOverlay
else
	echo -e "\nUsing GuestFish"
	if [ $skipmakingsquash -eq 0 ]; then
		rm grub-overlay/newroot/* -R -f	
		mkdir -p grub-overlay/newroot
		echo -e "\nBuilding SquashFS"
		
		guestfish --ro -a $guestfishimage -i << __EOF__
mksquashfs / grub-overlay/newroot/root.squash excludes:boot
__EOF__
		if [ "$luksbuild" -eq 1 ]; then
			echo -e "\nBuilding LUKS"
			pushd grub-overlay/newroot/
			dd if=/dev/zero of=encrypted bs=1M count=16
			cat root.squash >> encrypted
			echo -n "$lukspassword" | cryptsetup luksFormat encrypted -
			cryptsetup luksOpen encrypted cr_temp <<< $lukspassword
			dd if=root.squash of=/dev/mapper/cr_temp
			cryptsetup luksClose cr_temp
			rm root.squash -f
			popd
		fi
	fi
	echo "Building Init"
	pushd overlayfs
	buildInitOverlay
	chmod +x init

	mkdir -p ../grub-overlay/boot/$producttype
	if [ $useyum -eq 0 ]; then
		if [ -d temp ]; then
			rm temp -R -f
		fi
		mkdir temp
		pwd

		params="-i $(pwd)/../rc/rc.local /etc/rc.d/rc.local -i $(pwd)/modprobe.sh modprobe.sh -i /bin/chmod /bin/chmod -i $(pwd)/init myinit temp/initramfs.gz -f"
		if [ $adddriver -eq 1 ]; then
			#params="--drivers '$driverdata' $params"
			temp=""
			for x in $driverdata
			do
				temp="$temp -d $x"
			done
			params="$temp $params"
		fi
		echo "$params"
		if [ $usekernelversion -eq 0 ]; then
			dracut $params
		else
			params="$params $kernelversion"
			dracut $params
		fi

		pushd temp
		/usr/lib/dracut/skipcpio initramfs.gz  | gzip -d - | cpio -idv
		rm initramfs.gz
		rm init -f
		mv myinit init
		find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../../grub-overlay/boot/$producttype/initramfs.gz
		popd
		membuild=1
	else
		yumcommands
		membuild=1
	fi
	popd

	echo -e "\nBuilding ISO"
	if [ $usekernel -eq 1 ]; then
		cp $kernellocation grub-overlay/boot/$producttype/vmlinuz
	fi
	buildGrub :q
	cp grub.cfg grub-overlay/boot/grub/grub.cfg -f 

	grub2-mkrescue -o result/overlay-gf.iso grub-overlay/ -V $CDLABEL
	echo -e "\n\nOverlay Build Complete Using Guest Fish; saved to result/overlay-gf.iso"
fi

