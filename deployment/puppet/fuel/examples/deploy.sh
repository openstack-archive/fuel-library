#!/bin/bash
#    Copyright 2016 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.


TASKS="
hiera
host
cobbler
postgresql
rabbitmq
mcollective
astute
keystone
keystone_token_disable
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

exit 0
