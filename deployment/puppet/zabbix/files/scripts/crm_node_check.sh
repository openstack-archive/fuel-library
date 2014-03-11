#!/bin/bash
NODES=$(/usr/bin/sudo /usr/sbin/crm_resource --locate --quiet --resource $1)
HOSTNAME=$(/bin/hostname)
STATUS=0

for NODE in $NODES
do
  if [ "$NODE" == "$HOSTNAME" ]; then
    STATUS=1
  fi
done
echo $STATUS