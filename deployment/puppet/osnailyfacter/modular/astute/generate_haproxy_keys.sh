#!/bin/sh

while getopts ":i:h:o:p:" opt; do
  case $opt in
    i)  cluster_id=$OPTARG
        ;;
    h)  cn_name=$OPTARG
        ;;
    o)  open_ssl_keys=$OPTARG
        ;;
    p)  keys_path=$OPTARG
        ;;
  esac
done
BASE_PATH="$keys_path/$cluster_id"
CONF_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

generate_open_ssl_keys () {
  for i in $open_ssl_keys
    do
      local dir_path="$BASE_PATH/$i"
      local key_path="$dir_path/public_$i.key"
      local crt_path="$dir_path/public_$i.crt"
      mkdir -p $dir_path
      if [ ! -f $key_path ]; then
        env SSL_CN_NAME="$cn_name" bash -c "openssl req -newkey rsa:2048 -nodes -keyout $key_path -x509 -days 3650 -out $crt_path -config $CONF_PATH/openssl.cnf -extensions v3_req 2>&1"
        cat "$crt_path" "$key_path" > "$dir_path/public_$i.pem"
      else
        echo "Key $key_path already exists"
      fi
    done
}

generate_open_ssl_keys
