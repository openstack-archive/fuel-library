#!/bin/bash
LIBVIRT_DIR=$1
TEMPLATE_DIR=$2

if [ -z $2 ]; then
  echo "Usage $0: libvirt_dir template_dir"
  exit
fi

for i in $(find $TEMPLATE_DIR -type f -name \*\.xml)
do
  VM_NAME=$(basename $i|cut -f1 -d".")
  DST_XML=${LIBVIRT_DIR}/${VM_NAME}.xml
  cp -f $i $DST_XML
  ln -s $DST_XML ${LIBVIRT_DIR}/autostart/

  #name=${VM_NAME} envsubst < $i > $DST_XML

  DISK_FILE=$(xmllint --xpath "string(/domain/devices/disk/source/@file)" $DST_XML)
  qemu-img create -fqcow2 $DISK_FILE 10G
done