#!/bin/sh
# TODO: fill these vars

img_name=''
public=''
container_format=''
disk_format=''
min_ram=''
glance_properties=''
img_path=''

#############################################

# source the auth file
. '/root/openrc'
if [ $? -gt 0 ]; then
  echo "Could not source openrc!"
  exec 1
fi

# check if Glance is online
/usr/bin/glance image-list
if [ $? -gt 0 ]; then
  echo "Could not get a list of glance images!"
  exec 1
fi

# check if image is already uploaded
/usr/bin/glance image-list | grep "${img_name}"
if [ $? -eq 0 ]; then
  echo "Image '${img_name}' is already present!"
  exec 0
fi

# create an image
/usr/bin/glance image-create \
--name "${img_name}" \
--is-public "${public}" \
--container-format="${container_format}" \
--disk-format="${disk_format}" \
--min-ram="${min_ram}" \
"${glance_properties}" \
--file "${img_path}"
