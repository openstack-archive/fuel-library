#!/bin/bash
#
# assumes that resonable credentials have been stored at
# /root/auth
source /root/auth
wget http://uec-images.ubuntu.com/releases/11.10/release/ubuntu-11.10-server-cloudimg-amd64-disk1.img
glance add name="Ubuntu 11.10 cloudimg amd64" is_public=true container_format=ovf disk_format=qcow2 < ubuntu-11.10-server-cloudimg-amd64-disk1.img
glance index
