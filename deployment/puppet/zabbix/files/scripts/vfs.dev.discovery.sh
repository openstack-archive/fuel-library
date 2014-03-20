#!/bin/bash
#Zabbix vfs.dev.discovery implementation
#Send beer to <admin@fluda.net>
DEVS=`grep -v "major\|^$\|dm-\|[0-9]$" /proc/partitions | awk '{print $4}'`
POSITION=1
echo "{"
echo " \"data\":["
for DEV in $DEVS
do
    if [ $POSITION -gt 1 ]
    then
        echo ","
    fi
    echo -n " { \"{#DEVNAME}\": \"$DEV\"}"
    POSITION=$[POSITION+1]
done
echo ""
echo " ]"
echo "}"