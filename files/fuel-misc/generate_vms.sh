#!/bin/bash
LIBVIRT_DIR=$1
TEMPLATE_DIR=$2

#Defaults
DEFAULT_DISK_SIZE="50G"
DEFAULT_CPU_COUNT="2"
DEFAULT_MEM_COUNT="2"

shopt -s globstar nullglob


usage() {
  echo "Usage: $0 libvirt_dir template_dir"
  exit 1
}

create_vm_disks() {
  local VM_NAME=$1
  local XML_FILE=$2

  local DISK_NUMBER=$(xmlstarlet select -t -v 'count(/domain/devices/disk)' $XML_FILE)
  echo "Disks for $VM_NAME, total number $DISK_NUMBER"

  for DISK in $(seq 1 $DISK_NUMBER)
  do
    local DISK_TYPE=$(xmlstarlet select -t -v "/domain/devices/disk[$DISK]/@type" $XML_FILE)
    if [[ "$DISK_TYPE" != "file" ]]; then
      echo "Unknown disk type, ignoring"
      continue
    fi

    local DISK_FORMAT=$(xmlstarlet select -t -v "/domain/devices/disk[$DISK]/driver/@type" $XML_FILE)
    local DISK_PATH=$(xmlstarlet select -t -v "/domain/devices/disk[$DISK]/source/@file" $XML_FILE)
    local DISK_SIZE=$(xmlstarlet select -t -v "/domain/devices/disk[$DISK]/source/@size" $XML_FILE)
    DISK_SIZE=${DISK_SIZE:-$DEFAULT_DISK_SIZE}

    echo "Disk id: $DISK, disk type: $DISK_TYPE, disk format: $DISK_FORMAT, disk path: $DISK_PATH, disk size: $DISK_SIZE"

    if [[ -z "$DISK_FORMAT" || -z "$DISK_PATH" || -z "$DISK_SIZE" ]]; then
      echo "Failed to get disk details, ignoring"
      continue
    fi

    if [[ -f "$DISK_PATH" ]]; then
      echo "Disk file already exists, ignoring"
      continue
    fi

    qemu-img create -f $DISK_FORMAT $DISK_PATH $DISK_SIZE || exit 2

  done
}

verify_cpu() {
  local VM_NAME=$1
  local XML_FILE=$2

  local CPU_COUNT=$(xmlstarlet select -t -v '/domain/vcpu' $XML_FILE)
  if [[ -z "$CPU_COUNT" ]]; then
    echo "No cpu cores, setting to default"
    xmlstarlet edit --inplace --update '/domain/vcpu' -v $DEFAULT_CPU_COUNT $XML_FILE
  fi
}

verify_mem() {
  local VM_NAME=$1
  local XML_FILE=$2

  local MEM_COUNT=$(xmlstarlet select -t -v '/domain/memory' $XML_FILE)
  if [[ -z "$MEM_COUNT" ]]; then
    echo "No memory set, setting to default"
    xmlstarlet edit --inplace --update '/domain/memory' -v $DEFAULT_MEM_COUNT $XML_FILE
    xmlstarlet edit --inplace --update '/domain/memory/@unit' -v "GiB" $XML_FILE
  fi
}
# Stop script execution if script is sourced
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return
if (($# < 2)); then
  usage
fi

for TEMPLATE_XML in $TEMPLATE_DIR/**/*.xml
do
  VM_NAME=$(basename $TEMPLATE_XML | cut -f1 -d".")
  DST_XML=${LIBVIRT_DIR}/${VM_NAME}.xml

  #Copy VMs xml file to libvirt and ensure autostart
  if ! [[ -h "${LIBVIRT_DIR}/autostart/$VM_NAME.xml" ]]; then
    ln -s $DST_XML ${LIBVIRT_DIR}/autostart/
  fi
  cp -f $TEMPLATE_XML $DST_XML

  #Create disks for VMs
  create_vm_disks $VM_NAME $DST_XML

  #Verify cpu settings
  verify_cpu $VM_NAME $DST_XML

  #Verify memory settings
  verify_mem $VM_NAME $DST_XML

done

exit 0
