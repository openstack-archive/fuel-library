#!/bin/sh

while getopts ":i:o:s:f:p:" opt; do
  case $opt in
    i)  cluster_id=$OPTARG
        ;;
    o)  open_ssl_keys=$OPTARG
        ;;
    s)  ssh_keys=$OPTARG
        ;;
    f)  fernet_keys=$OPTARG
        ;;
    p)  keys_path=$OPTARG
        ;;
  esac
done

[ -z ${keys_path} ] && keys_path="/var/lib/fuel/keys"
declare -x RANDFILE=/root/.rnd

BASE_PATH=$keys_path/$cluster_id/

generate_open_ssl_keys () {
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

generate_ssh_keys () {
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

generate_fernet_keys () {
  for i in $fernet_keys
    do
      local dir_path=${BASE_PATH}fernet-keys/
      local key_path=$dir_path$i
      mkdir -p $dir_path
      if [ ! -f $key_path ]; then
#TODO:it is a hack to generate keys;
#the proper way is to use native keystone command for fernet initialization.
        openssl rand -base64 32 -out $key_path 2>&1
      else
        echo "Key $key_path already exists"
      fi
   done
}

generate_open_ssl_keys
generate_ssh_keys
generate_fernet_keys

