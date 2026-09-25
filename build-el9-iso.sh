#!/bin/bash

# Source ISO image
printf " -------------------\n"
printf " --- \e[32mISO Builder\e[0m ---\n"
printf " -------------------\n"
ISO_BOOT="OracleLinux-R9-U8-x86_64-boot-uek.iso"

if [ -f ${ISO_BOOT} ]; 
then 
  printf " ISO \"${ISO_BOOT}\" ... [\e[32mdone\e[0m]\n";
else
  printf " ISO \"${ISO_BOOT}\" ";
  wget -q -c "https://yum.oracle.com/ISOS/OracleLinux/OL9/u8/x86_64/"${ISO_BOOT}
  printf "was download ... [\e[32mdone\e[0m]\n";
fi

# Work folders
printf " Define working directory:"
MNT_BOOT="mount_boot"
WORK_DIR="iso_mod"
printf " \"${MNT_BOOT}\","
printf " \"${WORK_DIR}\"... [\e[32mdone\e[0m]\n"

# Clean and make dirs
printf " Make dirs "
sudo rm -rf "$WORK_DIR" "$MNT_BOOT"
mkdir -p "$WORK_DIR" "$MNT_BOOT"
printf "... [\e[32mdone\e[0m]\n"

# Mount source ISO
printf " Mount ISO Boot\n"
sudo mount -o loop "$ISO_BOOT" "$MNT_BOOT" 2>/dev/null
#ls -al ${MNT_BOOT}
printf " ... [\e[32mdone\e[0m]\n"

# Boot ISO
printf " Copy data "
cp -r "$MNT_BOOT"/. "$WORK_DIR"/
printf "... [\e[32mdone\e[0m]\n"

# Unmount ISO's
printf " Unmount ISO "
sudo umount "$MNT_BOOT"
rm -rf "$MNT_BOOT"
printf "... [\e[32mdone\e[0m]\n"

# BaseOS RPMs
printf " Get BaseOS RPMs "
mkdir -p "${WORK_DIR}/BaseOS/Packages"
cd "${WORK_DIR}/BaseOS/Packages"
wget -qc -i ../../../rpms-core.txt
cd ../../../
printf "... [\e[32mdone\e[0m]\n"

# ID's files
cat << 'EOF_TREEINFO' > "${WORK_DIR}/.treeinfo"
[variant-BaseOS]
id = BaseOS
name = BaseOS
packages = BaseOS
repository = BaseOS
type = variant
EOF_TREEINFO
cat << EOF_DISKINFO > "${WORK_DIR}/.discinfo"
`date +%s.%N`
Oracle Linux 9.8.0
x86_64
BaseOS
EOF_DISKINFO
echo " ID's files... done"


# Kickstart file
cp  `pwd`/ks1.cfg "$WORK_DIR"/ks1.cfg
echo " Kickstart... done"

# GRUB
GRUB_FILE="$WORK_DIR"/EFI/BOOT/grub.cfg
ISO_LABEL="OL9U8"
cat << 'EOF' > "$GRUB_FILE"
set default="0"
set timeout=20

menuentry 'Install Oracle Linux 9' --class fedora --class gnu-linux --class gnu --class os {
  linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=${ISO_LABEL} inst.btrfs inst.ks=hd:LABEL=${ISO_LABEL}:/ks1.cfg
  initrdefi /images/pxeboot/initrd.img
}

menuentry 'Go to UEFI' --class windows --class os {
  fwsetup
}

menuentry 'Reboot machine' --class os {
  reboot
}

menuentry 'Poweroff machine' --class os {
  halt
}
EOF
echo " GRUB... done"

# Create repository
printf " Build repository "
COMPS_FILE="d8d30e7e5b6651973b362152f5791172184c285b2e1985dcb3df5cfebc6d726d-comps.xml"
createrepo_c -g `pwd`"/${COMPS_FILE}" "${WORK_DIR}/BaseOS/"
printf "... done"

# Build new ISO
OUTPUT_ISO=`pwd`"/my-ol9u8.iso"
cd "$WORK_DIR"
xorriso -as mkisofs \
  -V "${ISO_LABEL}" \
  -o "${OUTPUT_ISO}" \
  -J -joliet-long -r \
  -e images/efiboot.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  .

cd ..