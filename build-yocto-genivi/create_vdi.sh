#!/bin/bash

# Convert kernel/rootfs images generated by build-yocto-qemux86
# into a .VDI image suitable to be executed from VirtualBox

# BIG FAT WARNING
# A few dangerous commands are executed as sudo and may destroy your host filesystem if buggy.
# USE AT YOUR OWN RISK - YOU HAVE BEEN WARNED!!!

TOPDIR=$PWD/tmp/build-gemini-5.0.0-qemux86

MACHINE=qemux86
FSTYPE=tar.bz2
KERNEL=$TOPDIR/tmp/deploy/images/$MACHINE/bzImage-$MACHINE.bin
ROOTFS=$TOPDIR/tmp/deploy/images/$MACHINE/gemini-image-$MACHINE.$FSTYPE

RAW_IMAGE=test.raw
VDI_IMAGE=test.vdi

MNT_ROOTFS=/tmp/rootfs

set -e
set -x

# Create QEMU image
# See http://en.wikibooks.org/wiki/QEMU/Images

qemu-img create -f raw $RAW_IMAGE 256M

# TODO: Also need to make part1 bootable?

fdisk $RAW_IMAGE <<END
n
p
1


w
END

#sfdisk -l $RAW_IMAGE

#fdisk -l $RAW_IMAGE
# ==> Partition 1 starts at sector 2048

# See http://stackoverflow.com/questions/1419489/loopback-mounting-individual-partitions-from-within-a-file-that-contains-a-parti
sudo kpartx -v -a $RAW_IMAGE | tee kpartx.tmp

# loop0p1
ROOTPART=`cut -d' ' -f3 kpartx.tmp`
echo "DBG: ROOTPART=$ROOTPART"

sudo mkfs -t ext3 /dev/mapper/$ROOTPART

mkdir -p $MNT_ROOTFS
sudo mount -o loop /dev/mapper/$ROOTPART $MNT_ROOTFS

sudo tar xvfj $ROOTFS -C $MNT_ROOTFS

# TODO: Should copy /boot/grub.conf to MNT_ROOTFS
# TODO: Grub install on /dev/mapper/$ROOTPART

sudo umount $MNT_ROOTFS

sudo kpartx -d $RAW_IMAGE

qemu-img convert -f raw -O vdi $RAW_IMAGE $VDI_IMAGE

# TODO: Test: Run QEMU against VDI_IMAGE
# TODO: Test: Run VirtualBox against VDI_IMAGE

#sudo losetup -a

# See also: http://libguestfs.org/

exit 0;

# EOF