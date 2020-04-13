Live DVD

Remember this is not an overlayfs, this is a live memory filesystem.  I don't have a good script to make an overlayfs yet (to save memory) so that's the next version

1)  Edit the GRUB Menu in grub/boot/grub.cfg

2)  Replace VMLINUZ with the appropriate Kernel in grub/boot/rhel8

3)  Guest mount the OS

	a) guestmount -a imagename -i newroot -o nonempty

4)  Run Build.sh


If you want EFI, make sure you install grub2-efi-x64-modules via yum install grub2-efi-x64-modules
