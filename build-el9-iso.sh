#!/bin/bash

# Source ISO image
echo " Get source ISO..."
ISO_DVD="${1}OracleLinux-R9-U8-x86_64-dvd.iso"
ISO_BOOT="${1}OracleLinux-R9-U8-x86_64-boot.iso"
#BOOT_ISO="${1}OracleLinux-R9-U8-x86_64-boot-uek.iso"
echo " - ${ISO_BOOT}"
echo " - ${ISO_DVD}"

# Work folders
echo " Working directory..."
MNT_DVD="mount_dvd"
MNT_BOOT="mount_boot"
WORK_DIR="iso_mod"
echo " - ${MNT_DVD}"
echo " - ${MNT_BOOT}"
echo " - ${WORK_DIR}"

echo "=== Building start ==="

# Clean and make dirs
sudo rm -rf "$WORK_DIR" "$MNT_BOOT" "$MNT_DVD"
mkdir -p "$WORK_DIR" "$MNT_BOOT" "$MNT_DVD"
echo " Dirs... done"

# Mount source ISO
sudo mount -o loop "$ISO_BOOT" "$MNT_BOOT"
sudo mount -o loop "$ISO_DVD" "$MNT_DVD"
echo " Mount... done"

#ls -al ${MNT_BOOT}
ls -al ${MNT_DVD}/AppStream/Packages/
ls -al ${MNT_DVD}/BaseOS/Packages/

# Boot ISO
cp -r "$MNT_BOOT"/. "$WORK_DIR"/
echo " Copy boot... done"

# BaseOS data
cp -r "$MNT_DVD"/BaseOS "$WORK_DIR"/
echo " BaseOS... done"

# ID's files
cp "$MNT_DVD"/.treeinfo "$WORK_DIR"/
cp "$MNT_DVD"/media.repo "$WORK_DIR"/
cp "$MNT_DVD"/images/efiboot.img "$WORK_DIR"/images/
echo " ID's files... done"

# AppStream data
mkdir -p "$WORK_DIR"/AppStream/Packages
KEEP_PATTERNS=("nano")
for pattern in "${KEEP_PATTERNS[@]}"; do
    find "$MNT_DVD"/AppStream/Packages/ -name "*${pattern}*" -exec cp {} "$WORK_DIR"/AppStream/Packages/ \; 2>/dev/null || true
done
echo " AppStream... done"
#ls -al ${WORK_DIR}
du -sh ${WORK_DIR}

# Unmount ISO's
sudo umount "$MNT_BOOT" "$MNT_DVD"
rm -rf "$MNT_BOOT" "$MNT_DVD"
echo " Unmount... done"

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
createrepo_c "$WORK_DIR"/AppStream/
#createrepo_c "$WORK_DIR"/BaseOS/
echo " Repository... done"

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