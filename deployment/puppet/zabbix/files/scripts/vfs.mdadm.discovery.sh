#!/bin/bash

COUNT=`cat /proc/mdstat | awk {'print $1;'} | egrep -e 'md?' | wc -l | sed -e 's/^ *//g' -e 's/ *$//g'`

#echo Quantity: $COUNT

echo "{"
echo -e "\t\"data\":[\n"

i=1
let COUNT=COUNT+1

while [ $i -lt $COUNT ]; do
        #echo Item: $i
        MDEV=`cat /proc/mdstat | awk {'print $1;'} | egrep -e 'md?' | sort -n | head -$i | tail -fn 1`
        let CHECK=COUNT-1
        if [ $i == $CHECK ]; then echo -e "\t{ \"{#MDEVICE}\":\"$MDEV\" }"
        else echo -e "\t{ \"{#MDEVICE}\":\"$MDEV\" },"
        fi
        let i=i+1
done

echo -e "\n\t]"
echo "}"