#!/bin/env bash

#
# Copyright 2013 Eucalyptus Systems, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

set -xe

ROOTLABEL=$_

if [ $# -ne 1 ]; then
	echo "Usage: $@ <attached volume device>"
	exit 1
fi

if [ -z "$EC2_URL" ]; then
	echo "Please source your Eucalyptus credentials (eucarc) before running this script."
	exit 1
fi

DEV=$1

# FIXME: test for existence of volume device
# FIXME: test for parted and rsync

# set up partitions
parted $DEV mklabel msdos
parted $DEV mkpart primary ext2 0% 100%
partprobe $DEV

# FIXME: detect ubuntu and use "cloudimg-rootfs" instead of rootdisk

# mount new filesystem
mkfs.ext3 "$DEV"1 -L $ROOTLABEL 
MOUNT=$(mktemp -d)
mount "$DEV"1 $MOUNT

# copy contents
rsync -avSHx / $MOUNT

# postprocessing
rm -f $MOUNT/etc/udev/rules.d/70-persistent-net.rules
sed -i /$(hostname)/d $MOUNT/etc/hosts
rm -f $MOUNT/var/lib/dhclient/*.leases

# set up grub
cp $MOUNT/usr/share/grub/x86_64-redhat/* $MOUNT/boot/grub

# not sure where this brain damage came from -- guessing that menu.lst is canonical
rm -f $MOUNT/boot/grub/grub.conf
rm -f $MOUNT/etc/grub.conf
ln -s menu.lst $MOUNT/boot/grub/grub.conf
ln -s ../boot/grub/menu.lst $MOUNT/etc/grub.conf

echo "(hd0) $DEV" > $MOUNT/tmp/device.map

mount -o bind /proc $MOUNT/proc
mount -o bind /dev $MOUNT/dev

chroot $MOUNT grub --batch --no-floppy --device-map=/tmp/device.map <<EOF
device (hd0) $DEV
root (hd0,0)
setup --stage2=/boot/grub/stage2 (hd0)
quit
EOF

chroot $MOUNT grubby --update-kernel=ALL --args="ro root=LABEL=$ROOTLABEL console=ttyS0"
sed -i 's/root (hd0)/root (hd0,0)/' $MOUNT/boot/grub/grub.conf

umount $MOUNT/proc
umount $MOUNT/dev
umount $MOUNT

sync
