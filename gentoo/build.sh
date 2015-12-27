#!/bin/sh -e
NCPUS=`nproc`
BASE_DIR=`pwd`

rm -rf tmp gentoo squashfs-root
if [ ! -d /usr/src/linux ]; then
    emerge gentoo-sources
fi
if [ ! -f /usr/bin/mksquashfs ]; then
    emerge squashfs-tools
fi
if [ ! -f install-amd64-minimal-20150924.iso ]; then
    wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/install-amd64-minimal-20150924.iso
fi
if [ "`mount |grep /mnt`" = "" ]; then
    mount -o loop,ro ./install-amd64-minimal-20150924.iso /mnt
fi
if [ ! -f gentoo.cpio ]; then
    xzcat /mnt/isolinux/gentoo.igz > gentoo.cpio
fi
mkdir gentoo
cd gentoo
cpio -i < ../gentoo.cpio
rm -rf lib/modules/*
cd -
unsquashfs /mnt/image.squashfs
umount /mnt
rm -rf squashfs-root/lib/modules/*
cp efi.config /usr/src/linux/.config
mkdir tmp
cp gentoo.cpio /usr/src/linux/rootfs.cpio
cd /usr/src/linux
make -j$NCPUS
make modules -j$NCPUS
INSTALL_MOD_PATH=$BASE_DIR/tmp make modules_install
cd -
cp -a $BASE_DIR/tmp/lib/modules/* gentoo/lib/modules
cp -a $BASE_DIR/tmp/lib/modules/* squashfs-root/lib/modules
mkdir -p gentoo/mnt/cdrom
mksquashfs ./squashfs-root gentoo/mnt/cdrom/image.squashfs
cd gentoo
patch init < $BASE_DIR/init.diff
cd -
cd /usr/src/linux
./scripts/gen_initramfs_list.sh $BASE_DIR/gentoo > list
./usr/gen_init_cpio list > rootfs.cpio
make -j$NCPUS
cd -
cp /usr/src/linux/arch/x86/boot/bzImage bootx64.efi
