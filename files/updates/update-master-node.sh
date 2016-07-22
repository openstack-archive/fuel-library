#!/bin/bash

set -x

[ -d '/var/log/puppet' ] || mkdir -p /var/log/puppet
LOGFILE=${LOGFILE:-/var/log/puppet/update_master_node.log}

exec > >(tee -i "${LOGFILE}")
exec 2>&1

echo 'Master node update is in progress'

yum clean all
yum update -y

bash -x /etc/puppet/modules/fuel/examples/deploy.sh

SERVICES="
astute
cobblerd
mcollective
nailgun
nginx
openstack-keystone
ostf
rabbitmq-server
oswl_flavor_collectord
oswl_image_collectord
oswl_keystone_user_collectord
oswl_tenant_collectord
oswl_vm_collectord
oswl_volume_collectord
receiverd
statsenderd
assassind"

service postgresql restart
sleep 32

for service in $SERVICES; do
  echo "Restarting $service"
  systemctl restart $service
done
