#!/bin/bash
LIBVIRT_DIR=$1
TEMPLATE_DIR=$2

#Defaults
DEFAULT_DISK_SIZE="10G"

if (($# < 2)); then
  echo "Usage $0: libvirt_dir template_dir"
  exit 1
fi

function create_vm_disks {
  VM_NAME=$1
  XML_FILE=$2

  DISK_NUMBER=$(xmllint --xpath "count(/domain/devices/disk)" $XML_FILE)
  echo "Disks for $VM_NAME, total number $DISK_NUMBER"

  for DISK in $(seq 1 $DISK_NUMBER)
  do
    DISK_TYPE=$(xmllint --xpath "string(/domain/devices/disk[$DISK]/@type)" $XML_FILE)
    if [ "$DISK_TYPE" != "file" ]; then
      echo "Unknown disk type, ignoring"
      continue
    fi

    DISK_FORMAT=$(xmllint --xpath "string(/domain/devices/disk[$DISK]/driver/@type)" $XML_FILE)
    DISK_PATH=$(xmllint --xpath "string(/domain/devices/disk[$DISK]/source/@file)" $XML_FILE)
    DISK_SIZE=$(xmllint --xpath "string(/domain/devices/disk[$DISK]/source/@size)" $XML_FILE)
    DISK_SIZE=${DISK_SIZE:-$DEFAULT_DISK_SIZE}

    echo "Disk id: $DISK, disk type: $DISK_TYPE, disk format: $DISK_FORMAT, disk path: $DISK_PATH, disk size: $DISK_SIZE"

    if [ -z "$DISK_FORMAT" -o -z "$DISK_PATH" -o -z "$DISK_SIZE" ]; then
      echo "Failed to get disk details, ignoring"
      continue
    fi

    if [ -f $DISK_PATH ]; then
      echo "Disk file already exists, ignoring"
      continue
    fi

    qemu-img create -f $DISK_FORMAT $DISK_PATH $DISK_SIZE

  done
  
}

for TEMPLATE_XML in $(find $TEMPLATE_DIR -type f -name \*\.xml)
do
  VM_NAME=$(basename $TEMPLATE_XML | cut -f1 -d".")
  DST_XML=${LIBVIRT_DIR}/${VM_NAME}.xml

  #Create disks for VMs
  create_vm_disks $VM_NAME $TEMPLATE_XML

  #Copy VMs xml file to libvirt and ensure autostart
  ln -s $DST_XML ${LIBVIRT_DIR}/autostart/
  cp -f $TEMPLATE_XML $DST_XML

done

exit 0
