#!/bin/sh

if [ -f '/etc/init.d/ceph-radosgw' ]; then
  service ceph-radosgw restart
elif [ -f '/etc/init.d/radosgw' ]; then
  service radosgw restart
else
  echo "RadosGW service not found!"
  exit 1
fi
