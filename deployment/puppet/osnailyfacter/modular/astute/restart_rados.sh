#!/bin/sh

if [ -f '/etc/init.d/ceph-radosgw' ]; then
  /etc/init.d/ceph-radosgw restart
elif [ -f '/etc/init.d/radosgw' ]; then
  /etc/init.d/radosgw restart
else
  echo "RadosGW service not found!"
  exit 1
fi
