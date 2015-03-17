#!/bin/sh
sudo ceph health | grep -q HEALTH_OK; if [ $? -eq 0 ]; then echo 1; else echo 0; fi
