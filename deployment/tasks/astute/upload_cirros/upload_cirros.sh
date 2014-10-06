#!/bin/sh

img_name='TestVM'
img_file='cirros-x86_64-disk.img'
public='true'
container_format='bare'
disk_format='qcow2'
min_ram='64'
glance_properties="murano_image_info='{\"title\": \"Murano Demo\", \"type\": \"cirros.demo\"}'"

#############################################

# find the correct image path
if [ -f "/usr/share/cirros-testvm/${img_file}" ]; then
  img_path="/usr/share/cirros-testvm/${img_file}"
elif [ -f "/opt/vm/${img_file}" ]; then
  img_path="/opt/vm/${img_file}"
else
  echo "Could not fine image file: ${img_file}!"
  exit 1
fi

# source the auth file
. '/root/openrc'
if [ $? -gt 0 ]; then
  echo "Could not source /root/openrc!"
  exit 1
fi

# check if Glance is online
/usr/bin/glance image-list 1>/dev/null 2>/dev/null
if [ $? -gt 0 ]; then
  echo "Could not get a list of glance images!"
  exit 1
fi

# check if image is already uploaded
/usr/bin/glance image-list | grep -q "${img_name}"
if [ $? -eq 0 ]; then
  echo "Image '${img_name}' is already present!"
  exit 0
fi

# create an image
/usr/bin/glance image-create \
--name "${img_name}" \
--is-public "${public}" \
--container-format="${container_format}" \
--disk-format="${disk_format}" \
--min-ram="${min_ram}" \
--property "${glance_properties}" \
--file "${img_path}"

ec="${?}"
if [ "${ec}" -eq "0" ]; then
  echo "Image '${img_name}' was uploaded from '${img_path}'"
  exit 0
else
  echo "Image '${img_name}' uploaded from '${img_path}' have FAILED!"
  exit "${ec}"
fi
