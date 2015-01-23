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

function generate_open_ssl_keys {
  for i in $open_ssl_keys
    do
      local dir_path=$BASE_PATH$i/
      local key_path=$dir_path$i.key
      mkdir -p $dir_path
      if [ ! -f $key_path ]; then
        openssl rand -base64 741 > $key_path 2>&1
      else
        echo 'Key $key_path already exists'
      fi
    done
}

function generate_ssh_keys {
  for i in $ssh_keys
    do
      local dir_path=$BASE_PATH$i/
      local key_path=$dir_path$i
      mkdir -p $dir_path
      if [ ! -f $key_path ]; then
        ssh-keygen -b 2048 -t rsa -N '' -f $key_path 2>&1
      else
        echo 'Key $key_path already exists'
      fi
    done
}

generate_open_ssl_keys
generate_ssh_keys
