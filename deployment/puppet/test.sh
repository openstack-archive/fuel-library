#!/bin/bash

a=
while [ -z $a ]; do
  a=$(grep -irn notification_driver neutron/)
  echo $a
  git checkout HEAD^1
done
