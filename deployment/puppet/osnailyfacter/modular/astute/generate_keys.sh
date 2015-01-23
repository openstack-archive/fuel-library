#!/bin/sh

while getopts ":i:o:s:p:" opt; do
  case $opt in
    i)  cluster_id=$OPTARG
        ;;
    o)  open_ssl_keys=$OPTARG
        ;;
    s)  ssh_keys=$OPTARG
        ;;
    p)  keys_path=$OPTARG
        ;;
  esac
done

BASE_PATH=$keys_path/$cluster_id/
for i in $open_ssl_keys
do
   dir_path=$BASE_PATH$i/
   key_path=$dir_path$i.key
   echo $dir_path
   if [ ! -d "$dir_path" ]; then
     mkdir -p $dir_path
   fi
   if [ ! -f $key_path ]; then
     openssl rand -base64 741 > $key_path 2>&1
   fi
done

for i in $ssh_keys
do
   dir_path=$BASE_PATH$i/
   key_path=$dir_path$i
   echo $dir_path
   if [ ! -d "$dir_path" ]; then
     mkdir -p $dir_path 
   fi
   if [ -f $key_path ]; then
     rm -rf $key_path
   fi
   ssh-keygen -b 2048 -t rsa -N '' -f $key_path 2>&1
done
