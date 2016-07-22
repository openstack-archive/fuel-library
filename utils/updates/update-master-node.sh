#!/bin/bash

yum -y update

TASKS="
hiera
host
cobbler
postgresql
mcollective
astute
keystone
keystone_token_disable
rabbitmq
nailgun
ostf
nginx_repo
nginx_services
client
rsyslog
puppetsync
"

for task in $TASKS; do
    cat <<EOF
##################################
DEPLOYMENT TASK: $task
##################################
EOF
    puppet apply -d -v --color false --detailed-exitcodes \
        "/etc/puppet/modules/fuel/examples/${task}.pp"
    PUPPET_RUN=$?
    if [[ $PUPPET_RUN -eq 1 ]] || [[ $PUPPET_RUN -gt 2 ]]; then
        echo "The were failures while running task: ${task} with exit code: ${PUPPET_RUN}"
        exit 1
    else
        echo "Deployment task has succeeded: ${task} with exit code: ${PUPPET_RUN}"
    fi
done

SERVICES="
astute
cobblerd
mcollective
nailgun
nginx
openstack-keystone
ostf
postgresql
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

for service in $SERVICES; do
echo "Restarting $service"
systemctl restart $service
done
