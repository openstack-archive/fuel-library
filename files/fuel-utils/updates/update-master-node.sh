#!/bin/bash

set -ex
set -o pipefail


# setup logging
[ -d '/var/log/puppet' ] || mkdir -p /var/log/puppet
LOGFILE="${LOGFILE:-/var/log/puppet/update_master_node.log}"

exec > >(tee -i "${LOGFILE}")
exec 2>&1


echo "Master node update is <in progress> (log: ${LOGFILE} )"

echo '<STAGE>: Packages...'
# upgrade packages
yum clean all
yum update -y

# systemd: load fresh units
systemctl daemon-reload


echo '<STAGE>: Puppet...'
# re-apply puppet master node configuration
bash -x /etc/puppet/modules/fuel/examples/deploy.sh


echo '<STAGE>: Services...'
# restart services
SERVICES="
astute
cobblerd
mcollective
nailgun
nginx
httpd
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
assassind
"

echo "Restarting postgresql..."
systemctl restart postgresql
sleep 32

for service in $SERVICES; do
    echo "Restarting ${service}..."
    systemctl restart "$service"
done

echo "Rebuilding bootstrap images"
fuel-bootstrap build --activate

echo; echo
echo "Master node update is <successfully complete> (log: ${LOGFILE} )"

exit 0
