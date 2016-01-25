#!/bin/bash

set -e

TASKS="
host
cobbler
postgresql
rabbitmq
mcollective
astute
keystone
nailgun
ostf
nginx_repo
nginx_services
client
"
LOGFILE=/var/log/puppet/deploy.log

for task in $TASKS; do
    cat >> $LOGFILE <<EOF
##################################
DEPLOYMENT TASK: $task
##################################
EOF
    puppet apply -d -v --color false --logdest $LOGFILE \
        /etc/puppet/modules/fuel/examples/${task}.pp
done
